from pydantic import BaseModel

class ImageDetails(BaseModel):
    cotton_type: str | None = None
    station: str | None = None
    lot_number: int | None = None
    
class Results(BaseModel):
    msfl: int | None = None
    ifl: int | None = None
    ml: int | None = None