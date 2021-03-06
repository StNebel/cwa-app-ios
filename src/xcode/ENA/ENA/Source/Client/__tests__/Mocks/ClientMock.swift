// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

@testable import ENA
import ExposureNotification

final class ClientMock {
	
	// MARK: - Creating a Mock Client.

	/// Creates a mock `Client` implementation with given default values.
	///
	/// - parameters:
	///		- availableDaysAndHours: return this value when the `availableDays(_:)` or `availableHours(_:)` is called, or an error if `urlRequestFailure` is passed.
	///		- downloadedPackage: return this value when `fetchDay(_:)` or `fetchHour(_:)` is called, or an error if `urlRequestFailure` is passed.
	///		- submissionError: when set, `submit(_:)` will fail with this error.
	///		- urlRequestFailure: when set, calls (see above) will fail with this error
	init(
		availableDaysAndHours: DaysAndHours = DaysAndHours(days: [], hours: []),
		downloadedPackage: SAPDownloadedPackage? = nil,
		submissionError: SubmissionError? = nil,
		urlRequestFailure: Client.Failure? = nil
	) {
		self.availableDaysAndHours = availableDaysAndHours
		self.downloadedPackage = downloadedPackage
		self.urlRequestFailure = urlRequestFailure

		if let error = submissionError {
			onSubmitCountries = { $2(.failure(error)) }
		}
	}

	init() {}

	// MARK: - Properties.

	var submissionResponse: KeySubmissionResponse?
	var urlRequestFailure: Client.Failure?
	var availableDaysAndHours: DaysAndHours = DaysAndHours(days: [], hours: [])
	var downloadedPackage: SAPDownloadedPackage?
	lazy var supportedCountries: [Country] = {
		// provide a default list of some countries
		let codes = ["DE", "IT", "ES", "PL", "NL", "BE", "CZ", "AT", "DK", "IE", "LT", "LV", "EE"]
		return codes.compactMap({ Country(countryCode: $0) })
	}()

	// MARK: - Configurable Mock Callbacks.

	var onAppConfiguration: (AppConfigurationCompletion) -> Void = { $0(nil) }
	var onGetTestResult: ((String, Bool, TestResultHandler) -> Void)?
	var onSubmitCountries: ((_ payload: CountrySubmissionPayload, _ isFake: Bool, _ completion: @escaping KeySubmissionResponse) -> Void) = { $2(.success(())) }
	var onGetRegistrationToken: ((String, String, Bool, @escaping RegistrationHandler) -> Void)?
	var onGetTANForExposureSubmit: ((String, Bool, @escaping TANHandler) -> Void)?
	var onSupportedCountries: ((@escaping CountryFetchCompletion) -> Void)?
}

extension ClientMock: Client {

	func availableDays(forCountry country: String, completion: @escaping AvailableDaysCompletionHandler) {
		if let failure = urlRequestFailure {
			completion(.failure(failure))
			return
		}
		completion(.success(availableDaysAndHours.days))
	}

	func availableHours(day: String, country: String, completion: @escaping AvailableHoursCompletionHandler) {
		if let failure = urlRequestFailure {
			completion(.failure(failure))
			return
		}
		completion(.success(availableDaysAndHours.hours))
	}

	func fetchDay(_ day: String, forCountry country: String, completion: @escaping DayCompletionHandler) {
		if let failure = urlRequestFailure {
			completion(.failure(failure))
			return
		}
		completion(.success(downloadedPackage ?? SAPDownloadedPackage(keysBin: Data(), signature: Data())))
	}

	func fetchHour(_ hour: Int, day: String, country: String, completion: @escaping HourCompletionHandler) {
		if let failure = urlRequestFailure {
			completion(.failure(failure))
			return
		}
		completion(.success(downloadedPackage ?? SAPDownloadedPackage(keysBin: Data(), signature: Data())))
	}
	
	func appConfiguration(completion: @escaping AppConfigurationCompletion) {
		onAppConfiguration(completion)
	}

	func exposureConfiguration(completion: @escaping ExposureConfigurationCompletionHandler) {
		completion(ENExposureConfiguration())
	}

	func supportedCountries(completion: @escaping CountryFetchCompletion) {
		guard let onSupportedCountries = self.onSupportedCountries else {
			completion(.success(supportedCountries))
			return
		}

		onSupportedCountries(completion)
	}

	func submit(payload: CountrySubmissionPayload, isFake: Bool, completion: @escaping KeySubmissionResponse) {
		onSubmitCountries(payload, isFake, completion)
	}

	func getRegistrationToken(forKey: String, withType: String, isFake: Bool, completion completeWith: @escaping RegistrationHandler) {
		guard let onGetRegistrationToken = self.onGetRegistrationToken else {
			completeWith(.success("dummyRegistrationToken"))
			return
		}

		onGetRegistrationToken(forKey, withType, isFake, completeWith)
	}

	func getTestResult(forDevice device: String, isFake: Bool, completion completeWith: @escaping TestResultHandler) {
		guard let onGetTestResult = self.onGetTestResult else {
			completeWith(.success(TestResult.positive.rawValue))
			return
		}

		onGetTestResult(device, isFake, completeWith)
	}

	func getTANForExposureSubmit(forDevice device: String, isFake: Bool, completion completeWith: @escaping TANHandler) {
		guard let onGetTANForExposureSubmit = self.onGetTANForExposureSubmit else {
			completeWith(.success("dummyTan"))
			return
		}

		onGetTANForExposureSubmit(device, isFake, completeWith)
	}
}
