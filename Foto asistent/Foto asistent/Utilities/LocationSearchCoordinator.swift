import Foundation
import MapKit
import Combine

class LocationSearchCoordinator: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    @Published var error: Error? = nil
    
    private var completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    private var querySubject = PassthroughSubject<String, Never>()
    private var resultType: MKLocalSearchCompleter.ResultType = .pointOfInterest
    
    private var searchTask: DispatchWorkItem?
    
    init(resultType: MKLocalSearchCompleter.ResultType = .pointOfInterest) {
        self.resultType = resultType
        super.init()
        
        setupCompleter()
        setupSearchDebounce()
    }
    
    // Změna přístupnosti metody na internal
    func setupCompleter() {
        completer.delegate = self
        completer.resultTypes = resultType
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.75, longitude: 15.5), // Česká republika
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )
    }
    
    private func setupSearchDebounce() {
        querySubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }
    
    func search(query: String) {
        querySubject.send(query)
    }
    
    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.error = nil
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isSearching = true
            self.error = nil
        }
        
        completer.queryFragment = query
    }
    
    func searchLocation(_ query: String) {
        // Zrušení předchozího vyhledávání
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
            }
            return
        }
        
        isSearching = true
        
        // Vytvoření nového vyhledávání s odložením
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.completer.queryFragment = query
        }
        
        // Naplánování vyhledávání s odložením
        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("LocationSearchCoordinator: Search failed with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.searchResults = []
            self.isSearching = false
            self.error = error
        }
    }
    
    func getAddressCoordinate(address: String, completion: @escaping (CLLocationCoordinate2D?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("LocationSearchCoordinator: Geocoding error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            if let location = placemarks?.first?.location?.coordinate {
                completion(location, nil)
            } else {
                completion(nil, NSError(domain: "LocationSearchCoordinator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Adresa nenalezena"]))
            }
        }
    }
}
