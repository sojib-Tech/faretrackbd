from pydantic import BaseModel


class BusStop(BaseModel):
    name: str
    distance_from_start_km: float


class BusRoute(BaseModel):
    id: str
    name_bn: str
    name_en: str
    route_no: str
    total_distance_km: float
    stops: list[BusStop]
    fare_matrix: list[list[float]]


class DdrRoute(BaseModel):
    serial: int
    id: str
    previous_route_no: str
    name_bn: str
    name_en: str
    route_no: str
    total_distance_km: float
    fare_per_km: float
    fare_51_seat_without_toll: float
    fare_80_seat_without_toll: float
    toll: float
    toll_per_passenger_51_seat: float
    toll_per_passenger_80_seat: float
    total_fare_51_seat: float
    total_fare_80_seat: float


class FareRequest(BaseModel):
    route_id: str
    from_stop: str
    to_stop: str


class FareResponse(BaseModel):
    route_id: str
    route_name_bn: str
    from_stop: str
    to_stop: str
    fare: float
    distance_km: float


class SearchResponse(BaseModel):
    query: str
    results: list[BusRoute]


class StopSearchResult(BaseModel):
    stop_name: str
    routes: list[dict]
