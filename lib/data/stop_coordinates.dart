import '../models/journey/stop_coordinate.dart';

class StopCoordinates {
  StopCoordinates._();

  static const Map<String, StopCoordinate> _byName = {
    'চিড়িয়াখানা': StopCoordinate(name: 'Zoo', nameBn: 'চিড়িয়াখানা', lat: 23.8150, lng: 90.3700),
    'মিরপুর-১': StopCoordinate(name: 'Mirpur-1', nameBn: 'মিরপুর-১', lat: 23.7925, lng: 90.3530),
    'মিরপুর-২': StopCoordinate(name: 'Mirpur-2', nameBn: 'মিরপুর-২', lat: 23.7975, lng: 90.3570),
    'মিরপুর-৬': StopCoordinate(name: 'Mirpur-6', nameBn: 'মিরপুর-৬', lat: 23.8010, lng: 90.3580),
    'মিরপুর-১০': StopCoordinate(name: 'Mirpur-10', nameBn: 'মিরপুর-১০', lat: 23.8040, lng: 90.3630),
    'মিরপুর-১১': StopCoordinate(name: 'Mirpur-11', nameBn: 'মিরপুর-১১', lat: 23.8070, lng: 90.3660),
    'মিরপুর-১২': StopCoordinate(name: 'Mirpur-12', nameBn: 'মিরপুর-১২', lat: 23.8120, lng: 90.3680),
    'মিরপুর-১৪': StopCoordinate(name: 'Mirpur-14', nameBn: 'মিরপুর-১৪', lat: 23.7880, lng: 90.3510),
    'মিরপুর রূপনগর': StopCoordinate(name: 'Mirpur Rupnagar', nameBn: 'মিরপুর রূপনগর', lat: 23.8160, lng: 90.3650),

    'টেকনিক্যাল': StopCoordinate(name: 'Technical', nameBn: 'টেকনিক্যাল', lat: 23.7800, lng: 90.3520),
    'শ্যামলী': StopCoordinate(name: 'Shyamoli', nameBn: 'শ্যামলী', lat: 23.7760, lng: 90.3580),
    'শ্যামলী রিং রোড': StopCoordinate(name: 'Shyamoli Ring Road', nameBn: 'শ্যামলী রিং রোড', lat: 23.7740, lng: 90.3560),
    'কল্যাণপুর': StopCoordinate(name: 'Kalyanpur', nameBn: 'কল্যাণপুর', lat: 23.7730, lng: 90.3620),
    'আসাদগেট': StopCoordinate(name: 'Asad Gate', nameBn: 'আসাদগেট', lat: 23.7680, lng: 90.3680),
    'কালশী': StopCoordinate(name: 'Kalshi', nameBn: 'কালশী', lat: 23.8100, lng: 90.3750),
    'পুরবী': StopCoordinate(name: 'Purobi', nameBn: 'পুরবী', lat: 23.8130, lng: 90.3720),
    'কাজীপাড়া': StopCoordinate(name: 'Kazipara', nameBn: 'কাজীপাড়া', lat: 23.8060, lng: 90.3700),
    'শেওড়াপাড়া': StopCoordinate(name: 'Shewrapara', nameBn: 'শেওড়াপাড়া', lat: 23.8080, lng: 90.3740),
    'শেওড়া বাজার': StopCoordinate(name: 'Shewra Bazar', nameBn: 'শেওড়া বাজার', lat: 23.8090, lng: 90.3760),

    'ফার্মগেট': StopCoordinate(name: 'Farmgate', nameBn: 'ফার্মগেট', lat: 23.7580, lng: 90.3880),
    'শাহবাগ': StopCoordinate(name: 'Shahbag', nameBn: 'শাহবাগ', lat: 23.7380, lng: 90.3960),
    'পল্টন': StopCoordinate(name: 'Paltan', nameBn: 'পল্টন', lat: 23.7330, lng: 90.4080),
    'জিপিও': StopCoordinate(name: 'GPO', nameBn: 'জিপিও', lat: 23.7310, lng: 90.4060),
    'গুলিস্তান': StopCoordinate(name: 'Gulistan', nameBn: 'গুলিস্তান', lat: 23.7290, lng: 90.4110),
    'মতিঝিল': StopCoordinate(name: 'Motijheel', nameBn: 'মতিঝিল', lat: 23.7330, lng: 90.4180),
    'কমলাপুর': StopCoordinate(name: 'Kamalapur', nameBn: 'কমলাপুর', lat: 23.7280, lng: 90.4220),
    'সায়েদাবাদ': StopCoordinate(name: 'Sayedabad', nameBn: 'সায়েদাবাদ', lat: 23.7150, lng: 90.4250),
    'যাত্রাবাড়ী': StopCoordinate(name: 'Jatrabari', nameBn: 'যাত্রাবাড়ী', lat: 23.7100, lng: 90.4310),
    'টিকাটুলি': StopCoordinate(name: 'Tikatuli', nameBn: 'টিকাটুলি', lat: 23.7210, lng: 90.4200),
    'প্রেসক্লাব': StopCoordinate(name: 'Press Club', nameBn: 'প্রেসক্লাব', lat: 23.7350, lng: 90.4030),

    'কাওরান বাজার': StopCoordinate(name: 'Kawran Bazar', nameBn: 'কাওরান বাজার', lat: 23.7530, lng: 90.3920),
    'বাংলামটর': StopCoordinate(name: 'Bangla Motor', nameBn: 'বাংলামটর', lat: 23.7500, lng: 90.3900),
    'মগবাজার': StopCoordinate(name: 'Moghbazar', nameBn: 'মগবাজার', lat: 23.7450, lng: 90.3950),
    'মৌচাক': StopCoordinate(name: 'Mouchak', nameBn: 'মৌচাক', lat: 23.7430, lng: 90.4000),
    'নিউমার্কেট': StopCoordinate(name: 'New Market', nameBn: 'নিউমার্কেট', lat: 23.7400, lng: 90.3830),
    'সাইন্সল্যাব': StopCoordinate(name: 'Science Lab', nameBn: 'সাইন্সল্যাব', lat: 23.7400, lng: 90.3780),
    'কলাবাগান': StopCoordinate(name: 'Kalabagan', nameBn: 'কলাবাগান', lat: 23.7420, lng: 90.3800),
    'নীলক্ষেত': StopCoordinate(name: 'Nilkhet', nameBn: 'নীলক্ষেত', lat: 23.7370, lng: 90.3820),
    'আজিমপুর': StopCoordinate(name: 'Azimpur', nameBn: 'আজিমপুর', lat: 23.7300, lng: 90.3850),
    'রাসেল স্কয়ার': StopCoordinate(name: 'Russell Square', nameBn: 'রাসেল স্কয়ার', lat: 23.7390, lng: 90.3780),
    'মানিক মিয়া': StopCoordinate(name: 'Manik Mia', nameBn: 'মানিক মিয়া', lat: 23.7650, lng: 90.3780),
    'মানিকমিয়া এভিনিউ': StopCoordinate(name: 'Manik Mia Avenue', nameBn: 'মানিকমিয়া এভিনিউ', lat: 23.7660, lng: 90.3790),
    'সক্রনবাদ': StopCoordinate(name: 'Shukrabad', nameBn: 'সক্রনবাদ', lat: 23.7450, lng: 90.3750),
    'কচুক্ষেত': StopCoordinate(name: 'Kochukhet', nameBn: 'কচুক্ষেত', lat: 23.7900, lng: 90.3550),
    'বিজয় স্মরণী': StopCoordinate(name: 'Bijoy Sarani', nameBn: 'বিজয় স্মরণী', lat: 23.7630, lng: 90.3870),
    'খামারবাড়ি মোড়': StopCoordinate(name: 'Khamarbari Moor', nameBn: 'খামারবাড়ি মোড়', lat: 23.7560, lng: 90.3890),

    'মহাখালী': StopCoordinate(name: 'Mohakhali', nameBn: 'মহাখালী', lat: 23.7750, lng: 90.4000),
    'গুলশান-১': StopCoordinate(name: 'Gulshan-1', nameBn: 'গুলশান-১', lat: 23.7780, lng: 90.4060),
    'বনানী': StopCoordinate(name: 'Banani', nameBn: 'বনানী', lat: 23.7900, lng: 90.4020),
    'কাকলী': StopCoordinate(name: 'Kakali', nameBn: 'কাকলী', lat: 23.7820, lng: 90.4050),
    'আগারগাঁও': StopCoordinate(name: 'Agargaon', nameBn: 'আগারগাঁও', lat: 23.7730, lng: 90.3850),
    'শিওমেলা': StopCoordinate(name: 'Shiromela', nameBn: 'শিওমেলা', lat: 23.7740, lng: 90.3800),
    'শিয়া মসজিদ': StopCoordinate(name: 'Shia Masjid', nameBn: 'শিয়া মসজিদ', lat: 23.7710, lng: 90.3720),
    'বসিলা': StopCoordinate(name: 'Bosila', nameBn: 'বসিলা', lat: 23.7540, lng: 90.3620),
    'মোহঃপুর': StopCoordinate(name: 'Mohammadpur', nameBn: 'মোহঃপুর', lat: 23.7600, lng: 90.3650),
    'শিয়ালড়া': StopCoordinate(name: 'Shialda', nameBn: 'শিয়ালড়া', lat: 23.7620, lng: 90.3580),
    'আদাবর': StopCoordinate(name: 'Adabor', nameBn: 'আদাবর', lat: 23.7640, lng: 90.3580),
    'মোহাম্মদপুর': StopCoordinate(name: 'Mohammadpur Town', nameBn: 'মোহাম্মদপুর', lat: 23.7580, lng: 90.3630),
    'মোহাম্মদপুর শিয়া মসজিদ': StopCoordinate(name: 'Mohammadpur Shia Mosque', nameBn: 'মোহাম্মদপুর শিয়া মসজিদ', lat: 23.7560, lng: 90.3610),
    'আটিবাজার': StopCoordinate(name: 'Atibazar', nameBn: 'আটিবাজার', lat: 23.7490, lng: 90.3540),
    'দিয়াবাড়ী': StopCoordinate(name: 'Diyabari', nameBn: 'দিয়াবাড়ী', lat: 23.8230, lng: 90.3720),
    'দিয়াবাড়ী চৌরাস্তা': StopCoordinate(name: 'Diyabari Chourasta', nameBn: 'দিয়াবাড়ী চৌরাস্তা', lat: 23.8250, lng: 90.3740),

    'বাড্ডা': StopCoordinate(name: 'Badda', nameBn: 'বাড্ডা', lat: 23.7810, lng: 90.4300),
    'বাড্ডা লিংক রোড': StopCoordinate(name: 'Badda Link Road', nameBn: 'বাড্ডা লিংক রোড', lat: 23.7790, lng: 90.4280),
    'নতুন বাজার': StopCoordinate(name: 'Notun Bazar', nameBn: 'নতুন বাজার', lat: 23.7800, lng: 90.4250),
    'রামপুরা': StopCoordinate(name: 'Rampura', nameBn: 'রামপুরা', lat: 23.7720, lng: 90.4350),
    'রামপুরা ব্রীজ': StopCoordinate(name: 'Rampura Bridge', nameBn: 'রামপুরা ব্রীজ', lat: 23.7700, lng: 90.4370),
    'বনশ্রী': StopCoordinate(name: 'Banasree', nameBn: 'বনশ্রী', lat: 23.7640, lng: 90.4400),
    'মেরাদিয়া': StopCoordinate(name: 'Meradia', nameBn: 'মেরাদিয়া', lat: 23.7600, lng: 90.4450),
    'মেরাদিয়া বাজার': StopCoordinate(name: 'Meradia Bazar', nameBn: 'মেরাদিয়া বাজার', lat: 23.7580, lng: 90.4460),
    'মেরুল': StopCoordinate(name: 'Merul', nameBn: 'মেরুল', lat: 23.7760, lng: 90.4320),
    'কুড়িল বিশ্বরোড': StopCoordinate(name: 'Kuril Bishwaroad', nameBn: 'কুড়িল বিশ্বরোড', lat: 23.7850, lng: 90.4180),
    'কুড়িল ফ্লাইওভার': StopCoordinate(name: 'Kuril Flyover', nameBn: 'কুড়িল ফ্লাইওভার', lat: 23.7870, lng: 90.4200),
    'ইসিবি চতুর': StopCoordinate(name: 'ECB Square', nameBn: 'ইসিবি চতুর', lat: 23.8100, lng: 90.3820),

    'উত্তরা': StopCoordinate(name: 'Uttara', nameBn: 'উত্তরা', lat: 23.8750, lng: 90.3790),
    'জসিমউদ্দিন': StopCoordinate(name: 'Jasimuddin', nameBn: 'জসিমউদ্দিন', lat: 23.8680, lng: 90.3810),
    'আব্দুল্লাহপুর': StopCoordinate(name: 'Abdullahpur', nameBn: 'আব্দুল্লাহপুর', lat: 23.8600, lng: 90.3830),
    'কামারপাড়া': StopCoordinate(name: 'Kamarpara', nameBn: 'কামারপাড়া', lat: 23.8520, lng: 90.3860),
    'এয়ারপোর্ট': StopCoordinate(name: 'Airport', nameBn: 'এয়ারপোর্ট', lat: 23.8450, lng: 90.3980),
    'বিমানবন্দর': StopCoordinate(name: 'Airport Terminal', nameBn: 'বিমানবন্দর', lat: 23.8440, lng: 90.4000),
    'ধউর': StopCoordinate(name: 'Dhour', nameBn: 'ধউর', lat: 23.8700, lng: 90.3700),
    'ধওর': StopCoordinate(name: 'Dhour Alt', nameBn: 'ধওর', lat: 23.8700, lng: 90.3700),
    'কুর্মিটোলা জেনারেল হাসপাতাল': StopCoordinate(name: 'Kurmitola GH', nameBn: 'কুর্মিটোলা জেনারেল হাসপাতাল', lat: 23.8580, lng: 90.3900),

    'আঙলিয়া': StopCoordinate(name: 'Anglia', nameBn: 'আঙলিয়া', lat: 23.8400, lng: 90.3650),
    'নবীনগর': StopCoordinate(name: 'Nabinnagar', nameBn: 'নবীনগর', lat: 23.8350, lng: 90.3500),
    'সাভার': StopCoordinate(name: 'Savar', nameBn: 'সাভার', lat: 23.8550, lng: 90.2640),
    'গাবতলী': StopCoordinate(name: 'Gabtoli', nameBn: 'গাবতলী', lat: 23.7680, lng: 90.3430),
    'হেমায়েতপুর': StopCoordinate(name: 'Hemayetpur', nameBn: 'হেমায়েতপুর', lat: 23.7800, lng: 90.3170),
    'ইপিজেড': StopCoordinate(name: 'EPZ', nameBn: 'ইপিজেড', lat: 23.8300, lng: 90.2400),
    'নন্দন পার্ক': StopCoordinate(name: 'Nandan Park', nameBn: 'নন্দন পার্ক', lat: 23.8300, lng: 90.2500),
    'নন্দনপার্ক': StopCoordinate(name: 'Nandan Park Alt', nameBn: 'নন্দনপার্ক', lat: 23.8300, lng: 90.2500),
    'ফ্যান্টাসি': StopCoordinate(name: 'Fantasy', nameBn: 'ফ্যান্টাসি', lat: 23.8300, lng: 90.2800),
    'ফ্যান্টাসি কিংডম': StopCoordinate(name: 'Fantasy Kingdom', nameBn: 'ফ্যান্টাসি কিংডম', lat: 23.8300, lng: 90.2800),
    'আমিন বাজার': StopCoordinate(name: 'Amin Bazar', nameBn: 'আমিন বাজার', lat: 23.7850, lng: 90.3100),
    'কাঁচপুর ব্রীজ': StopCoordinate(name: 'Kanchpur Bridge', nameBn: 'কাঁচপুর ব্রীজ', lat: 23.7000, lng: 90.4500),
    'জাপান গার্ডেন সিটি': StopCoordinate(name: 'Japan Garden City', nameBn: 'জাপান গার্ডেন সিটি', lat: 23.7740, lng: 90.3560),

    'সদরঘাট': StopCoordinate(name: 'Sadarghat', nameBn: 'সদরঘাট', lat: 23.7100, lng: 90.4030),
    'ফুলবাড়িয়া': StopCoordinate(name: 'Fulbaria', nameBn: 'ফুলবাড়িয়া', lat: 23.7340, lng: 90.4140),
    'তাঁতি বাজার': StopCoordinate(name: 'Tanti Bazar', nameBn: 'তাঁতি বাজার', lat: 23.7180, lng: 90.4100),
    'বাবু বাজার ব্রীজ': StopCoordinate(name: 'Babu Bazar Bridge', nameBn: 'বাবু বাজার ব্রীজ', lat: 23.7130, lng: 90.4120),
    'চন কুটিয়া': StopCoordinate(name: 'Chan Kutia', nameBn: 'চন কুটিয়া', lat: 23.7050, lng: 90.4080),
    'কেরানীগঞ্জ': StopCoordinate(name: 'Keraniganj', nameBn: 'কেরানীগঞ্জ', lat: 23.6850, lng: 90.3850),
    'সাইনবোর্ড': StopCoordinate(name: 'Signboard', nameBn: 'সাইনবোর্ড', lat: 23.7050, lng: 90.4400),
    'শনির আখড়া': StopCoordinate(name: 'Shani Akhra', nameBn: 'শনির আখড়া', lat: 23.7020, lng: 90.4450),
    'হানিফ ফ্লাইওভার': StopCoordinate(name: 'Hanif Flyover', nameBn: 'হানিফ ফ্লাইওভার', lat: 23.7060, lng: 90.4430),
    'চানখারপুল': StopCoordinate(name: 'Chankharpul', nameBn: 'চানখারপুল', lat: 23.7250, lng: 90.4160),

    'মাওয়া ফেরীঘাট': StopCoordinate(name: 'Mawa Ferry Ghat', nameBn: 'মাওয়া ফেরীঘাট', lat: 23.5800, lng: 90.3400),
    'নারায়নগঞ্জ': StopCoordinate(name: 'Narayanganj', nameBn: 'নারায়নগঞ্জ', lat: 23.6400, lng: 90.5000),
    'নারায়নগঞ্জ লিংক রোড': StopCoordinate(name: 'Narayanganj Link Road', nameBn: 'নারায়নগঞ্জ লিংক রোড', lat: 23.6420, lng: 90.4980),
    'চাষাড়া বাসস্ট্যান্ড': StopCoordinate(name: 'Chashara Stand', nameBn: 'চাষাড়া বাসস্ট্যান্ড', lat: 23.6450, lng: 90.5050),

    'দৈনিক বাংলা': StopCoordinate(name: 'Dainik Bangla', nameBn: 'দৈনিক বাংলা', lat: 23.7300, lng: 90.4130),
    'শাপলা চতুর': StopCoordinate(name: 'Shapla Chattar', nameBn: 'শাপলা চতুর', lat: 23.7260, lng: 90.4150),
    'আরামবাগ': StopCoordinate(name: 'Arambagh', nameBn: 'আরামবাগ', lat: 23.7240, lng: 90.4180),

    'গাবতলী মোড়': StopCoordinate(name: 'Gabtoli Moor', nameBn: 'গাবতলী মোড়', lat: 23.7690, lng: 90.3450),
    'বকশিবাজার': StopCoordinate(name: 'Baksibazar', nameBn: 'বকশিবাজার', lat: 23.7260, lng: 90.4130),
    'ঢাকেশ্বরী': StopCoordinate(name: 'Dhakeshwari', nameBn: 'ঢাকেশ্বরী', lat: 23.7240, lng: 90.4110),
    'খিলক্ষেত': StopCoordinate(name: 'Khilkhet', nameBn: 'খিলক্ষেত', lat: 23.7930, lng: 90.4150),
    'রাজলক্ষ্মী': StopCoordinate(name: 'Rajlakshmi', nameBn: 'রাজলক্ষ্মী', lat: 23.7880, lng: 90.4200),
    'আজমপুর': StopCoordinate(name: 'Azampur', nameBn: 'আজমপুর', lat: 23.7950, lng: 90.4180),
    'হাউস বিল্ডিং': StopCoordinate(name: 'House Building', nameBn: 'হাউস বিল্ডিং', lat: 23.7960, lng: 90.4160),
    'কুড়িল চৌরাস্তা': StopCoordinate(name: 'Kuril Chourasta', nameBn: 'কুড়িল চৌরাস্তা', lat: 23.7860, lng: 90.4190),
    'নদ্দা': StopCoordinate(name: 'Nadda', nameBn: 'নদ্দা', lat: 23.7830, lng: 90.4220),
    'বসুন্ধরা': StopCoordinate(name: 'Bashundhara', nameBn: 'বসুন্ধরা', lat: 23.7950, lng: 90.4250),
    'যমুনা ফিউচার পার্ক': StopCoordinate(name: 'Jamuna Future Park', nameBn: 'যমুনা ফিউচার পার্ক', lat: 23.7920, lng: 90.4200),
    'বাঁশতলা': StopCoordinate(name: 'Bashtola', nameBn: 'বাঁশতলা', lat: 23.7800, lng: 90.4270),
    'শাহজাদপুর': StopCoordinate(name: 'Shahjadpur', nameBn: 'শাহজাদপুর', lat: 23.7770, lng: 90.4300),
    'উত্তর বাড্ডা': StopCoordinate(name: 'Uttar Badda', nameBn: 'উত্তর বাড্ডা', lat: 23.7830, lng: 90.4290),
    'মধ্য বাড্ডা': StopCoordinate(name: 'Madhya Badda', nameBn: 'মধ্য বাড্ডা', lat: 23.7810, lng: 90.4300),

    'পোস্তগোলা': StopCoordinate(name: 'Postogola', nameBn: 'পোস্তগোলা', lat: 23.7050, lng: 90.4150),
    'পোস্তগোলা ব্রীজ': StopCoordinate(name: 'Postogola Bridge', nameBn: 'পোস্তগোলা ব্রীজ', lat: 23.7060, lng: 90.4160),
    'ইকুরিয়া': StopCoordinate(name: 'Ikuria', nameBn: 'ইকুরিয়া', lat: 23.7030, lng: 90.4200),
    'টিটিপাড়া': StopCoordinate(name: 'Titipara', nameBn: 'টিটিপাড়া', lat: 23.7120, lng: 90.4250),
    'খিলগাও ফ্লাইওভার': StopCoordinate(name: 'Khilgaon Flyover', nameBn: 'খিলগাও ফ্লাইওভার', lat: 23.7180, lng: 90.4300),
    'মালিবাগ চৌধুরীপাড়া': StopCoordinate(name: 'Malibagh Chowdhurypara', nameBn: 'মালিবাগ চৌধুরীপাড়া', lat: 23.7380, lng: 90.4320),
    'মালিবাগ': StopCoordinate(name: 'Malibagh', nameBn: 'মালিবাগ', lat: 23.7400, lng: 90.4300),
    'মুগদা': StopCoordinate(name: 'Mugda', nameBn: 'মুগদা', lat: 23.7200, lng: 90.4350),
    'কাকরাইল': StopCoordinate(name: 'Kakrail', nameBn: 'কাকরাইল', lat: 23.7350, lng: 90.4150),

    'খেজুর বাগান': StopCoordinate(name: 'Khejur Bagan', nameBn: 'খেজুর বাগান', lat: 23.7550, lng: 90.3700),
    'নর্দাপাড়া ব্রীজ': StopCoordinate(name: 'Nordapara Bridge', nameBn: 'নর্দাপাড়া ব্রীজ', lat: 23.7560, lng: 90.4420),
    'মল্যাহাজীর মোড়': StopCoordinate(name: 'Mollahaji Moor', nameBn: 'মল্যাহাজীর মোড়', lat: 23.7540, lng: 90.4440),
    'ত্রিমোহনী': StopCoordinate(name: 'Trimohoni', nameBn: 'ত্রিমোহনী', lat: 23.7580, lng: 90.4430),
    'ড্রোজাহাজ ক্রসিং': StopCoordinate(name: 'Drossakh Crossing', nameBn: 'ড্রোজাহাজ ক্রসিং', lat: 23.7850, lng: 90.3990),
    'ওয়্যারলেস': StopCoordinate(name: 'Wireless', nameBn: 'ওয়্যারলেস', lat: 23.7780, lng: 90.3950),
    'জাহাঙ্গীর গেট': StopCoordinate(name: 'Jahangir Gate', nameBn: 'জাহাঙ্গীর গেট', lat: 23.7700, lng: 90.3910),
    'জিয়া উদ্যান': StopCoordinate(name: 'Zia Uddyan', nameBn: 'জিয়া উদ্যান', lat: 23.7680, lng: 90.3900),
    'শিশু মেলা': StopCoordinate(name: 'Shishu Mela', nameBn: 'শিশু মেলা', lat: 23.7720, lng: 90.3750),
    'সৈনিক ক্লাব': StopCoordinate(name: 'Sainik Club', nameBn: 'সৈনিক ক্লাব', lat: 23.7920, lng: 90.4000),
    'চেয়ারম্যান বাড়ি': StopCoordinate(name: 'Chairman Bari', nameBn: 'চেয়ারম্যান বাড়ি', lat: 23.7850, lng: 90.3980),
    'স্টাফ রোড': StopCoordinate(name: 'Staff Road', nameBn: 'স্টাফ রোড', lat: 23.7900, lng: 90.3950),
    'মৎস্য ভবন': StopCoordinate(name: 'Matsya Bhaban', nameBn: 'মৎস্য ভবন', lat: 23.7400, lng: 90.3980),
    'হাইকোর্ট': StopCoordinate(name: 'High Court', nameBn: 'হাইকোর্ট', lat: 23.7370, lng: 90.4010),

    'অরিজিনাল দশ': StopCoordinate(name: 'Original Dash', nameBn: 'অরিজিনাল দশ', lat: 23.8030, lng: 90.3590),
    'কালাপানি': StopCoordinate(name: 'Kalapani', nameBn: 'কালাপানি', lat: 23.8180, lng: 90.3670),
    'বঙ্গবন্ধু': StopCoordinate(name: 'Bangabandhu', nameBn: 'বঙ্গবন্ধু', lat: 23.8150, lng: 90.3650),
    'কাজিপাড়া': StopCoordinate(name: 'Kazipara', nameBn: 'কাজিপাড়া', lat: 23.8060, lng: 90.3700),
    'মোঃ জিলুর রহমান ফ্লাইওভার': StopCoordinate(name: 'Moz Zillur Rahman Flyover', nameBn: 'মোঃ জিলুর রহমান ফ্লাইওভার', lat: 23.8020, lng: 90.3740),
    'মাকট প্লাজা': StopCoordinate(name: 'Mahtab Plaza', nameBn: 'মাকট প্লাজা', lat: 23.8200, lng: 90.3770),
    'পল্লবী': StopCoordinate(name: 'Pallabi', nameBn: 'পল্লবী', lat: 23.8140, lng: 90.3690),
    'ধানমন্ডি': StopCoordinate(name: 'Dhanmondi', nameBn: 'ধানমন্ডি', lat: 23.7500, lng: 90.3750),
    'আসাদ এভিনিউ': StopCoordinate(name: 'Asad Avenue', nameBn: 'আসাদ এভিনিউ', lat: 23.7650, lng: 90.3720),
  };

  static final Map<String, StopCoordinate> _normalizedName = {
    for (final e in _byName.entries) _normalize(e.key): e.value,
  };

  static String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
  }

  static StopCoordinate? find(String name) {
    return _byName[name] ?? _normalizedName[_normalize(name)];
  }

  static List<StopCoordinate> get all => _byName.values.toList();

  static List<StopCoordinate> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return _byName.values.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.nameBn.contains(query) ||
          s.nameBn.toLowerCase().contains(q);
    }).toList();
  }
}
