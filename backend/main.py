from typing import Optional
from fastapi import APIRouter, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from models import BusRoute, DdrRoute, FareRequest, FareResponse, SearchResponse
from routes.route_data import ROUTES
from routes.ddr_route_data import DDR_ROUTES

app = FastAPI(
    title="FareTrack BD API",
    description="ঢাকা মেট্রো যাত্রী ও পণ্য পরিবহন কমিটির বাস ভাড়ার ডেটা API",
    version="2.0.0",
)

API_PREFIX = "/api/v2"

router = APIRouter(prefix=API_PREFIX)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

FARE_RATE_PER_KM = 2.53
MINIMUM_FARE = 10.0
DDR_FARE_RATE_PER_KM = 2.20


def get_fare(route: dict, from_idx: int, to_idx: int) -> Optional[float]:
    fare_matrix = route["fare_matrix"]
    row = from_idx if from_idx < to_idx else to_idx
    col = to_idx if from_idx < to_idx else from_idx
    col_idx = col - row - 1
    if row >= len(fare_matrix):
        return None
    if col_idx < 0 or col_idx >= len(fare_matrix[row]):
        return None
    return fare_matrix[row][col_idx]


@app.get("/")
def root():
    return {
        "app": "FareTrack BD API",
        "version": "2.0.0",
        "total_routes": len(ROUTES),
        "total_ddr_routes": len(DDR_ROUTES),
        "api_prefix": API_PREFIX,
        "endpoints": {
            "routes": f"{API_PREFIX}/routes",
            "route_by_id": f"{API_PREFIX}/routes/{{route_id}}",
            "fare_calculate": f"{API_PREFIX}/fare/calculate",
            "search": f"{API_PREFIX}/search?q={{query}}",
            "stops": f"{API_PREFIX}/stops/{{stop_name}}",
            "intercity_routes": f"{API_PREFIX}/intercity-routes",
            "intercity_route_by_id": f"{API_PREFIX}/intercity-routes/{{route_id}}",
        },
    }


app.include_router(router)


@router.get("/routes", response_model=list[BusRoute])
def get_routes():
    """Get all metro bus routes"""
    return ROUTES


@router.get("/intercity-routes", response_model=list[DdrRoute])
def get_intercity_routes():
    """Get all intercity (DDR) routes"""
    return DDR_ROUTES


@router.get("/routes/{route_id}", response_model=BusRoute)
def get_route(route_id: str):
    """Get a specific metro route by ID"""
    for r in ROUTES:
        if r["id"] == route_id:
            return r
    raise HTTPException(status_code=404, detail=f"Route {route_id} not found")


@router.get("/intercity-routes/{route_id}", response_model=DdrRoute)
def get_intercity_route(route_id: str):
    """Get a specific intercity (DDR) route by ID"""
    for r in DDR_ROUTES:
        if r["id"] == route_id:
            return r
    raise HTTPException(status_code=404, detail=f"Intercity route {route_id} not found")


@router.post("/fare/calculate", response_model=FareResponse)
def calculate_fare(req: FareRequest):
    """Calculate fare between two stops on a metro route"""
    route = None
    for r in ROUTES:
        if r["id"] == req.route_id:
            route = r
            break
    if not route:
        raise HTTPException(status_code=404, detail=f"Route {req.route_id} not found")

    from_idx = None
    to_idx = None
    stops = route["stops"]
    for i, s in enumerate(stops):
        if s["name"] == req.from_stop:
            from_idx = i
        if s["name"] == req.to_stop:
            to_idx = i

    if from_idx is None:
        raise HTTPException(status_code=404, detail=f"Stop '{req.from_stop}' not found on route")
    if to_idx is None:
        raise HTTPException(status_code=404, detail=f"Stop '{req.to_stop}' not found on route")

    fare = get_fare(route, from_idx, to_idx)
    if fare is None:
        raise HTTPException(status_code=500, detail="Could not calculate fare")

    distance_km = abs(stops[to_idx]["distance_from_start_km"] - stops[from_idx]["distance_from_start_km"])

    return FareResponse(
        route_id=route["id"],
        route_name_bn=route["name_bn"],
        from_stop=req.from_stop,
        to_stop=req.to_stop,
        fare=fare,
        distance_km=round(distance_km, 2),
    )


@router.get("/search", response_model=SearchResponse)
def search_routes(q: str = Query(..., min_length=1)):
    """Search metro routes by name or stop name"""
    ql = q.lower()
    results = []
    for r in ROUTES:
        if (ql in r["name_bn"].lower() or
            ql in r["name_en"].lower() or
            ql in r["route_no"].lower() or
            any(ql in s["name"].lower() for s in r["stops"])):
            results.append(r)
    return SearchResponse(query=q, results=results)


@router.get("/search-all")
def search_all(q: str = Query(..., min_length=1)):
    """Search both metro and intercity routes"""
    ql = q.lower()
    metro_results = []
    ddr_results = []

    for r in ROUTES:
        if (ql in r["name_bn"].lower() or
            ql in r["name_en"].lower() or
            ql in r["route_no"].lower() or
            any(ql in s["name"].lower() for s in r["stops"])):
            metro_results.append({"type": "metro"} | dict(r))

    for r in DDR_ROUTES:
        if (ql in r["name_bn"].lower() or
            ql in r["name_en"].lower() or
            ql in r["route_no"].lower()):
            ddr_results.append({"type": "intercity"} | dict(r))

    return {
        "query": q,
        "metro_count": len(metro_results),
        "intercity_count": len(ddr_results),
        "metro_results": metro_results,
        "intercity_results": ddr_results,
    }


@router.get("/stops/{stop_name}")
def find_stop(stop_name: str):
    """Find all metro routes containing a stop"""
    ql = stop_name.lower()
    routes_found = []
    for r in ROUTES:
        matching_stops = [s["name"] for s in r["stops"] if ql in s["name"].lower()]
        if matching_stops:
            routes_found.append({
                "route_id": r["id"],
                "route_name_bn": r["name_bn"],
                "matching_stops": matching_stops,
            })
    return {
        "query": stop_name,
        "routes_count": len(routes_found),
        "routes": routes_found,
    }


@router.get("/calculate-by-distance")
def calculate_fare_by_distance(distance_km: float = Query(..., gt=0)):
    """Calculate metro fare based on distance using standard rate"""
    fare = distance_km * FARE_RATE_PER_KM
    if fare < MINIMUM_FARE:
        fare = MINIMUM_FARE
    return {
        "distance_km": distance_km,
        "rate_per_km": FARE_RATE_PER_KM,
        "minimum_fare": MINIMUM_FARE,
        "fare": round(fare, 2),
        "type": "metro",
    }


@router.get("/calculate-intercity-fare")
def calculate_intercity_fare(distance_km: float = Query(..., gt=0)):
    """Calculate intercity fare based on distance using DDR rate"""
    fare = distance_km * DDR_FARE_RATE_PER_KM
    return {
        "distance_km": distance_km,
        "rate_per_km": DDR_FARE_RATE_PER_KM,
        "fare_51_seat": round(fare, 2),
        "fare_80_seat": round(fare, 2),
        "type": "intercity",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
