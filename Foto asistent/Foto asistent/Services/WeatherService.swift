import Foundation
import CoreLocation

struct WeatherData: Codable {
    let temperature: Double
    let condition: String
    let icon: String
    let humidity: Int
    let windSpeed: Double
    let description: String
}

class WeatherService: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var isLoading = false
    
    private let apiKey = "288adbc8c50c90f341e1d369bfb76832"
    
    func fetchWeather(for location: String, date: Date) {
        // Kontrola, zda je datum v rozsahu předpovědi (max 5 dní dopředu)
        let daysFromNow = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if daysFromNow > 5 || daysFromNow < 0 {
            // Datum je mimo dostupný rozsah předpovědi
            DispatchQueue.main.async {
                self.isLoading = false
                self.weatherData = nil
            }
            return
        }
        
        isLoading = true
        
        // Zjednodušená implementace pro demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.weatherData = WeatherData(
                temperature: Double.random(in: 15...25),
                condition: "Sunny",
                icon: "sun.max.fill",
                humidity: Int.random(in: 40...80),
                windSpeed: Double.random(in: 0...10),
                description: "Slunečno"
            )
            self.isLoading = false
        }
    }
    
    private func fetchCurrentWeather(lat: Double, lon: Double) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=cs"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            weatherData = nil
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data, error == nil else { 
                    self?.weatherData = nil
                    return 
                }
                
                do {
                    let result = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    self?.weatherData = WeatherData(
                        temperature: result.main.temp,
                        condition: result.weather.first?.main ?? "Unknown",
                        icon: self?.getSystemIcon(from: result.weather.first?.icon ?? "") ?? "questionmark",
                        humidity: result.main.humidity,
                        windSpeed: result.wind.speed,
                        description: result.weather.first?.description ?? ""
                    )
                } catch {
                    print("Error parsing current weather data: \(error)")
                    self?.weatherData = nil
                }
            }
        }.resume()
    }
    
    private func fetchWeatherForecast(lat: Double, lon: Double, targetDate: Date) {
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=cs"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            weatherData = nil
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data, error == nil else { 
                    self?.weatherData = nil
                    return 
                }
                
                do {
                    let result = try JSONDecoder().decode(ForecastResponse.self, from: data)
                    
                    // Najdi nejbližší časový slot k zadanému datu
                    let targetTimestamp = targetDate.timeIntervalSince1970
                    let closestForecast = result.list.min { forecast1, forecast2 in
                        abs(forecast1.dt - targetTimestamp) < abs(forecast2.dt - targetTimestamp)
                    }
                    
                    guard let forecast = closestForecast else {
                        self?.weatherData = nil
                        return
                    }
                    
                    self?.weatherData = WeatherData(
                        temperature: forecast.main.temp,
                        condition: forecast.weather.first?.main ?? "Unknown",
                        icon: self?.getSystemIcon(from: forecast.weather.first?.icon ?? "") ?? "questionmark",
                        humidity: forecast.main.humidity,
                        windSpeed: forecast.wind.speed,
                        description: forecast.weather.first?.description ?? ""
                    )
                } catch {
                    print("Error parsing forecast data: \(error)")
                    self?.weatherData = nil
                }
            }
        }.resume()
    }
    
    private func getSystemIcon(from weatherIcon: String) -> String {
        switch weatherIcon {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "questionmark"
        }
    }
}

struct WeatherResponse: Codable {
    let main: Main
    let weather: [Weather]
    let wind: Wind
    
    struct Main: Codable {
        let temp: Double
        let humidity: Int
    }
    
    struct Weather: Codable {
        let main: String
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
}

struct ForecastResponse: Codable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: WeatherResponse.Main
        let weather: [WeatherResponse.Weather]
        let wind: WeatherResponse.Wind
    }
}
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: WeatherResponse.Main
        let weather: [WeatherResponse.Weather]
        let wind: WeatherResponse.Wind
    }

