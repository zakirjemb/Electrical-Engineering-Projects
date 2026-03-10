export class WeatherData {
    time: string;
    precipitation: number;
    temperatureMax: number;
    temperatureMin: number;
    windDirection: number;
    windspeedMean: number;
    rainSpot: string;
    relativeHumidityMean: number;
    

    constructor(data: any) {
        this.time = data.time;
        this.precipitation = data.precipitation;
        this.temperatureMax = data.temperatureMax;
        this.windspeedMean = data.windspeedMean;
        this.temperatureMin = data.temperatureMin;
        this.windDirection = data.windDirection;
        this.rainSpot = data.rainSpot;
        this.relativeHumidityMean = data.relativeHumidityMean;
      
    }
}