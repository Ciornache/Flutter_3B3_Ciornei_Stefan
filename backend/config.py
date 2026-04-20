import os
from dotenv import load_dotenv

load_dotenv()

API_FOOTBALL_KEY = os.getenv("API_FOOTBALL_KEY", "")
API_FOOTBALL_KEY_SECONDARY = os.getenv("API_FOOTBALL_KEY_SECONDARY", "")
API_FOOTBALL_BASE_URL = os.getenv(
    "API_FOOTBALL_BASE_URL", "https://v3.football.api-sports.io"
).rstrip("/")
ESPN_BASE_URL = os.getenv(
    "ESPN_BASE_URL", "https://site.api.espn.com/apis/site/v2/sports"
).rstrip("/")
PORT = int(os.getenv("PORT", "5000"))
DEBUG = os.getenv("FLASK_DEBUG", "0") == "1"
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///sport_scores.db")
FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-key.json")


COUNTRIES_TTL = 60 * 60 * 24 * 30        
LEAGUES_TTL = 60 * 60 * 24 * 7          
FIXTURES_TTL = 60 * 10                  
DETAILS_LIVE_TTL = 30                  
DETAILS_FINISHED_TTL = 60 * 60 * 24 * 30

STATUS_UPCOMING = "upcoming"
STATUS_LIVE = "live"
STATUS_FINISHED = "finished"
STATUS_POSTPONED = "postponed"
STATUS_CANCELLED = "cancelled"
STATUS_UNKNOWN = "unknown"

FOOTBALL_STATUS_MAP = {
    "TBD": STATUS_UPCOMING, "NS": STATUS_UPCOMING,
    "1H": STATUS_LIVE, "HT": STATUS_LIVE, "2H": STATUS_LIVE, "ET": STATUS_LIVE,
    "BT": STATUS_LIVE, "P": STATUS_LIVE, "LIVE": STATUS_LIVE, "INT": STATUS_LIVE,
    "FT": STATUS_FINISHED, "AET": STATUS_FINISHED, "PEN": STATUS_FINISHED,
    "PST": STATUS_POSTPONED, "SUSP": STATUS_POSTPONED,
    "CANC": STATUS_CANCELLED, "ABD": STATUS_CANCELLED,
    "AWD": STATUS_CANCELLED, "WO": STATUS_CANCELLED,
}

SPORTS = [
    {"id": "football", "name": "Football", "icon_key": "football"},
    {"id": "american_football", "name": "American Football", "icon_key": "american_football"},
    {"id": "basketball", "name": "Basketball", "icon_key": "basketball"},
    {"id": "hockey", "name": "Hockey", "icon_key": "hockey"},
]

CONTINENTS = [
    {"name": "World", "emoji": "\U0001F310"},
    {"name": "Europe", "emoji": "\U0001F1EA\U0001F1FA"},
    {"name": "Asia", "emoji": "\U0001F30F"},
    {"name": "Africa", "emoji": "\U0001F30D"},
    {"name": "North America", "emoji": "\U0001F30E"},
    {"name": "South America", "emoji": "\U0001F30E"},
    {"name": "Oceania", "emoji": "\U0001F30A"},
    {"name": "Antarctica", "emoji": "\U0001F9CA"},
]

ESPN_LOGO_BASE = "https://a.espncdn.com/i/teamlogos/leagues/500"

ESPN_LEAGUES = [
    {"id": "nba", "name": "NBA", "sport_id": "basketball", "logo": f"{ESPN_LOGO_BASE}/nba.png"},
    {"id": "wnba", "name": "WNBA", "sport_id": "basketball", "logo": f"{ESPN_LOGO_BASE}/wnba.png"},
    {"id": "mens-college-basketball", "name": "NCAA Men's Basketball", "sport_id": "basketball", "logo": f"{ESPN_LOGO_BASE}/ncaa.png"},
    {"id": "womens-college-basketball", "name": "NCAA Women's Basketball", "sport_id": "basketball", "logo": f"{ESPN_LOGO_BASE}/ncaa.png"},
    {"id": "nbl", "name": "NBL (Australia)", "sport_id": "basketball", "logo": f"{ESPN_LOGO_BASE}/nbl.png"},
    {"id": "nfl", "name": "NFL", "sport_id": "american_football", "logo": f"{ESPN_LOGO_BASE}/nfl.png"},
    {"id": "college-football", "name": "NCAA Football", "sport_id": "american_football", "logo": f"{ESPN_LOGO_BASE}/ncaa.png"},
    {"id": "nhl", "name": "NHL", "sport_id": "hockey", "logo": f"{ESPN_LOGO_BASE}/nhl.png"},
    {"id": "mens-college-hockey", "name": "NCAA Men's Hockey", "sport_id": "hockey", "logo": f"{ESPN_LOGO_BASE}/ncaa.png"},
    {"id": "womens-college-hockey", "name": "NCAA Women's Hockey", "sport_id": "hockey", "logo": f"{ESPN_LOGO_BASE}/ncaa.png"},
]

SPORT_TO_ESPN_SLUG = {
    "basketball": "basketball",
    "american_football": "football",
    "hockey": "hockey",
}

COUNTRY_CONTINENT = {
    "GB": "Europe", "FR": "Europe", "DE": "Europe", "IT": "Europe", "ES": "Europe",
    "PT": "Europe", "NL": "Europe", "BE": "Europe", "CH": "Europe", "AT": "Europe",
    "PL": "Europe", "CZ": "Europe", "SE": "Europe", "NO": "Europe", "DK": "Europe",
    "FI": "Europe", "RU": "Europe", "UA": "Europe", "GR": "Europe", "TR": "Europe",
    "RO": "Europe", "BG": "Europe", "HR": "Europe", "HU": "Europe", "SK": "Europe",
    "SI": "Europe", "IE": "Europe", "IS": "Europe", "LU": "Europe", "MT": "Europe",
    "CY": "Europe", "AL": "Europe", "BA": "Europe", "RS": "Europe", "ME": "Europe",
    "MK": "Europe", "BY": "Europe", "MD": "Europe", "LT": "Europe", "LV": "Europe",
    "EE": "Europe",
    "JP": "Asia", "CN": "Asia", "IN": "Asia", "KR": "Asia", "TH": "Asia",
    "VN": "Asia", "MY": "Asia", "SG": "Asia", "ID": "Asia", "PH": "Asia",
    "BD": "Asia", "PK": "Asia", "IR": "Asia", "IQ": "Asia", "SA": "Asia",
    "AE": "Asia", "IL": "Asia", "KZ": "Asia", "UZ": "Asia", "TJ": "Asia",
    "AF": "Asia", "KG": "Asia", "TM": "Asia", "HK": "Asia", "TW": "Asia",
    "MO": "Asia", "MN": "Asia", "KH": "Asia", "LA": "Asia", "MM": "Asia",
    "BT": "Asia", "NP": "Asia", "LK": "Asia", "MV": "Asia", "QA": "Asia",
    "BH": "Asia", "KW": "Asia", "OM": "Asia", "YE": "Asia", "JO": "Asia",
    "LB": "Asia", "SY": "Asia",
    "ZA": "Africa", "EG": "Africa", "NG": "Africa", "KE": "Africa", "MA": "Africa",
    "GH": "Africa", "UG": "Africa", "ET": "Africa", "TZ": "Africa", "SD": "Africa",
    "DZ": "Africa", "SN": "Africa", "CI": "Africa", "CM": "Africa", "BW": "Africa",
    "ZW": "Africa", "MW": "Africa", "MZ": "Africa", "ZM": "Africa", "RW": "Africa",
    "BJ": "Africa", "BF": "Africa", "GA": "Africa", "CG": "Africa", "CD": "Africa",
    "AO": "Africa", "NA": "Africa", "SC": "Africa", "MU": "Africa", "TN": "Africa",
    "LY": "Africa", "GM": "Africa", "GW": "Africa", "GN": "Africa", "ML": "Africa",
    "MR": "Africa", "NE": "Africa", "TG": "Africa", "DJ": "Africa", "SO": "Africa",
    "ER": "Africa", "SS": "Africa", "CF": "Africa", "TD": "Africa", "CV": "Africa",
    "US": "North America", "CA": "North America", "MX": "North America",
    "CR": "North America", "PA": "North America", "BZ": "North America",
    "GT": "North America", "HN": "North America", "NI": "North America",
    "SV": "North America", "BS": "North America", "JM": "North America",
    "TT": "North America", "CU": "North America", "DO": "North America",
    "HT": "North America",
    "BR": "South America", "AR": "South America", "CO": "South America",
    "PE": "South America", "VE": "South America", "CL": "South America",
    "EC": "South America", "BO": "South America", "PY": "South America",
    "UY": "South America", "GY": "South America", "SR": "South America",
    "AQ": "Antarctica",
    "AD": "Europe", "AM": "Europe", "AZ": "Europe", "FO": "Europe", "GE": "Europe",
    "GI": "Europe", "XK": "Europe", "LI": "Europe", "SM": "Europe",
    "GB-ENG": "Europe", "GB-SCT": "Europe", "GB-WLS": "Europe", "GB-NIR": "Europe",
    "AG": "North America", "AW": "North America", "BB": "North America",
    "BM": "North America", "CW": "North America", "GD": "North America",
    "GP": "North America",
    "BI": "Africa", "SZ": "Africa", "LS": "Africa", "LR": "Africa",
    "PS": "Asia",
    "AU": "Oceania", "NZ": "Oceania", "FJ": "Oceania",
}
