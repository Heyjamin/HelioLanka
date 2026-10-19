//
//  SolarForcastModel.swift
//  HelioLanka
//
//  Created by G P M A Nuwan Jeewantha on 2026-10-19.
//

import CoreML
import Foundation

/// On-device solar generation forecaster.
///  Preference order: Core ML model --> JSON gradient-boosting trees --> weather heuristic
struct SolarForecastModel: Sendable {
    struct DayForecast: Identifiable, Sendable {
        var id: Date {day}
        let day: Date
        let predictedKwh: Double
    }
    
    struct WeatherDayFeatures: Sendable {
        var avgTempC: Double = 28
        var cloudCoverPct: Double = 55
        var humidityPct: Double = 75
        var precipitationMm: Double = 2
        var shortwaveRadiationWm2: Double = 220
    }
    
    struct ForecastContext: Sendable{
        var capacityKwp: Double = 5
        var historyKwh: [Double]
        var weatherByDay: [WeatherDayFeatures]
    }
    
    private let engine: any ForecastingEngine
    
    init(){
        if let core = CoreMLForecastEngine.loadFromBundle() {
            engine = core
        } else if let json = JSONTreeForecastEngine.loadFromBundle() {
            engine = json
        } else {
            engine = HeuristicForecastEngine()
        }
    }
    
    func forecast(context: ForecastContext, days: Int = 7) -> [DayForecast]{
        var history = context.historyKwh
        var out: [DayForecast] = []
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        
        for i in 0..<days{
            guard let day = cal.date(byAdding: .day, value: i + 1, to: start) else {continue}
            let weather = i < context.weatherByDay.count
            ? context.weatherByDay[i]
            : (context.weatherByDay.last ?? WeatherDayFeatures())
            let features = Self.featureVector(
                day: day,
                capacityKwp: context.capacityKwp,
                history: history,
                weather: weather
            )
            let raw = max(0, engine.predict(features:features))
            let rounded = (raw * 10).rounded() / 10
            out.append(DayForecast(day: day, predictedKwh: rounded))
            history.append(rounded)
        }
        return out
    }
    
    var engineName: String { engine.name }
    
    static func featureVector(
        day: Date,
        capacityKwp: Double,
        history: [Double],
        weather: WeatherDayFeatures
    ) -> [String: Double] {
        let cal = Calendar.current
        let lag1 = history.last ?? 6
        let lag7 = history.count >= 7 ? history[history.count - 7] : lag1
        let window = Array(history.suffix(7))
        let mean7 = window.isEmpty ? lag1 : window.reduce(0, +) / Double(window.count)
        let std7: Double = {
            guard window.count > 1 else { return 1.2 }
            let m = mean7
            let var_ = window.map { ($0 - m) * ($0 - m) }.reduce(0, +) / Double(window.count)
            return max(0.1, sqrt(var_))
        }()
        
        // Training used Monday = 0 ... sunday = 6.
        let weekday = (cal.component(.weekday, from: day) + 5) % 7
        let month = Double(cal.component(.month, from: day))
        let doy = Double(cal.ordinality(of: .day, in: .year, for: day) ?? 1)
        
        return [
            "capacity_kwp": capacityKwp,
            "day_of_week": Double(weekday),
            "month": month,
            "day_of_year": doy,
            "lag_1_kwh": lag1,
            "lag_7_kwh": lag7,
            "rolling_7_mean_kwh": mean7,
            "rolling_7_std_kwh": std7,
            "avg_temp_c": weather.avgTempC,
            "cloud_cover_pct": weather.cloudCoverPct,
            "humidity_pct": weather.humidityPct,
            "precipitation_mm": weather.precipitationMm,
            "shortwave_radiation_wm2": weather.shortwaveRadiationWm2,
        ]
    }
    
    ///  One weather row per local day, oldest first. Humidity is not in the API payload; 75 is the training default.
    static func dailyWeatherFeatures(from hourly: [WeatherPoint]) -> [WeatherDayFeatures] {
        var map: [Date: [WeatherPoint]] = [:]
        let cal = Calendar.current
        for point in hourly {
            let day = cal.startOfDay (for: point.timeUtc)
            map[day, default: []].append(point)
        }
        return map.keys.sorted().map { day in
            let points = map[day] ?? []
            let temps = points.compactMap(\.temperatureC)
            let clouds = points.compactMap(\.cloudCoverPercent)
            let radiation = points.compactMap(\.shortwaveRadiationWm2)
            let rain = points.compactMap(\.precipitationMm).reduce(0, +)
            return WeatherDayFeatures(
                avgTempC: temps.isEmpty ? 28 : temps.reduce(0, +) / Double(temps.count),
                cloudCoverPct: clouds.isEmpty ? 55 : clouds.reduce(0, +) / Double(clouds.count),
                humidityPct: 75,
                precipitationMm: rain,
                shortwaveRadiationWm2: radiation.isEmpty ? 220 : radiation.reduce(0, +) / Double(radiation.count)
            )
        }
    }
    
}

private protocol ForecastingEngine: Sendable {
    var name: String { get }
    func predict(features: [String: Double]) -> Double
}

private struct HeuristicForecastEngine: ForecastingEngine {
    let name = "heuristic"
    func predict(features: [String : Double]) -> Double {
        let baseline = features["rolling_7_mean_kwh"] ?? 8
        let radiation = features["shortwave_radiation_wm2"] ?? 200
        let factor = min(1.4, max(0.4, radiation / 250.0))
        return baseline * factor
    }
}

private final class InputScaler: @unchecked Sendable {
    let features: [String]
    let mean: [Double]
    let scale: [Double]
    
    init?(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "input_scaler", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = obj["features"] as? [String],
              let mean = obj["mean"] as? [Double],
              let scale = obj["scale"] as? [Double],
              features.count == mean.count, features.count == scale.count
        else {return nil}
        self.features = features
        self.mean = mean
        self.scale = scale
    }
    
    func transform(_ raw: [String: Double]) -> [String: Double]{
        var out: [String: Double] = [:]
        for (i, name) in features.enumerated() {
            let value = raw[name] ?? mean[i]
            let s = abs(scale[i]) < 1e-9 ? 1.0 : scale[i]
            out[name] = (value-mean[i])/s
        }
        return out
    }
    
    func ordered(_ raw: [String: Double]) -> [Double] {
        let scaled = transform(raw)
        return features.map { scaled[$0] ?? 0 }
    }
}

private final class CoreMLForecastEngine: ForecastingEngine, @unchecked Sendable{
    let name = "coreml"
    private let model: MLModel
    private let scaler: InputScaler
    
    init (model:MLModel, scaler: InputScaler){
        self.model = model
        self.scaler = scaler
    }
    
    static func loadFromBundle() -> CoreMLForecastEngine? {
        guard let scaler = InputScaler() else { return nil }
        let url = Bundle.main.url(forResource: "SolarGenerationForecaster", withExtension: "mlmodelc")
        ?? Bundle.main.url(forResource: "SolarGenerationForecaster", withExtension: "mlmodel")
        guard let url else { return nil }
        do {
            let compiled: URL
            if url.pathExtension == "mlmodel"{
                compiled = try MLModel.compileModel(at: url)
            }else{
                compiled = url
            }
            let model = try MLModel(contentsOf: compiled)
            return CoreMLForecastEngine(model: model, scaler: scaler)
        }catch{
            return nil
        }
    }
    
    func predict(features: [String : Double]) -> Double {
        let scaled = scaler.transform(features)
        guard let provider = try? MLDictionaryFeatureProvider(dictionary: scaled.mapValues{MLFeatureValue(double: $0)}),
              let out = try? model.prediction(from: provider)
                else { return features ["rolling_7_mean_kwh"] ?? 0 }
        if let value = out.featureValue(for: "predicted_kwh")?.doubleValue {
            return value
        }
        for name in out.featureNames{
            if let value = out.featureValue(for: name)?.doubleValue { return value}
        }
        return 0
    }
}

private final class JSONTreeForecastEngine: ForecastingEngine, @unchecked Sendable {
    let name = "json-gbdt"
    private let scaler: InputScaler
    private let learningRate: Double
    private let prior: Double
    private let trees: [Tree]
    
    struct Tree {
        let left: [Int]
        let right: [Int]
        let feature: [Int]
        let threshold: [Double]
        let value: [Double]
    }
    
    init(scaler: InputScaler, learningRate: Double, prior: Double, trees: [Tree]){
        self.scaler = scaler
        self.learningRate = learningRate
        self.prior = prior
        self.trees = trees
    }
    
    static func loadFromBundle() -> JSONTreeForecastEngine? {
        guard let scaler = InputScaler(),
              let url = Bundle.main.url(forResource: "SolarGenerationForecaster", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lr = obj["learning_rate"] as? Double,
              let prior = obj["init_prior"] as? Double,
              let estimators = obj["estimators"] as? [[String: Any]]
        else {return nil}
        
        var trees: [Tree] = []
        for estimator in estimators {
            guard let left = estimator["children_left"] as? [Int],
                  let right = estimator["children_right"] as? [Int],
                  let feature = estimator["feature"] as? [Int],
                  let threshold = estimator["threshold"] as? [Double],
                  let value = estimator["value"] as? [Double]
                    else { continue }
            trees.append(Tree(left: left, right: right, feature: feature, threshold: threshold, value: value))
        }
        guard !trees.isEmpty else { return nil }
        return JSONTreeForecastEngine(scaler: scaler, learningRate: lr, prior: prior, trees: trees)
    }
    
    func predict(features: [String: Double]) -> Double {
        let x = scaler.ordered(features)
        var prediction = prior
        for tree in trees {
            prediction += learningRate * evaluate(tree, x: x)
        }
        return prediction
    }
    
    private func evaluate(_ tree: Tree, x: [Double]) -> Double {
        var node = 0
        while tree.left[node] != -1 {
            let feature = tree.feature[node]
            let value = (feature >= 0 && feature < x.count) ? x[feature] : 0
            node = value <= tree.threshold[node] ? tree.left[node] : tree.right[node]
        }
        return tree.value[node]
    }
}
