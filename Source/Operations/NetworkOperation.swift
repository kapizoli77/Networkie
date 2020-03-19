//
//  NetworkOperation.swift
//  Networkie
//

import Foundation

// Abstract class to manage networrk operations

open class NetworkOperation: Operation {
    // MARK: - Properties

    public private(set) var identifier: String
    public weak var delegate: NetworkOperationDelegate?

    open override var isAsynchronous: Bool {
        return true
    }

    private var _isReady: Bool
    open override var isReady: Bool {
        get { return _isReady }
        set { update({ _isReady = newValue }, key: "isReady") }
    }

    private var _isExecuting: Bool
    open override var isExecuting: Bool {
        get { return _isExecuting }
        set {
            update({ _isExecuting = newValue }, key: "isExecuting")
            if newValue {
                delegate?.operationDidStart(self)
            }
        }
    }

    private var _isFinished: Bool
    open override var isFinished: Bool {
        get { return _isFinished }
        set {
            update({ _isFinished = newValue }, key: "isFinished")
            if newValue {
                delegate?.operationDidFinish(self)
            }
        }
    }

    private var _isCancelled: Bool
    open override var isCancelled: Bool {
        get { return _isCancelled }
        set { update({ _isCancelled = newValue }, key: "isCancelled") }
    }

    private var _isSuccess: Bool
    open var isSuccess: Bool {
        get { return _isSuccess }
        set { update({ _isSuccess = newValue }, key: "isSuccess") }
    }

    private var _isInterrupted: Bool
    open var isInterrupted: Bool {
        get { return _isInterrupted }
        set { update({ _isInterrupted = newValue }, key: "isInterrupted") }
    }

    private func update(_ change: () -> Void, key: String) {
        willChangeValue(forKey: key)
        change()
        didChangeValue(forKey: key)
    }

    // MARK: - Initialization

    public init(identifier: String, delegate: NetworkOperationDelegate?) {
        _isReady = true
        _isExecuting = false
        _isFinished = false
        _isCancelled = false
        _isSuccess = false
        _isInterrupted = false
        self.identifier = identifier
        self.delegate = delegate

        super.init()

        name = "Network Operation"
    }

    // MARK: - Functions

    // Used only inclass and by subclasses. Externally you should use `cancel`.
    func finish() {
        debugPrint("\(name!) operation finished.")

        isExecuting = false
        isFinished = true
    }

    func interrupt() {
        debugPrint("\(name!) operation interrupted.")

        isExecuting = false
        isInterrupted = true
        isFinished = true
    }

    func main(completion: @escaping (Bool) -> Void) {}

    // MARK: - Operation functions

    open override func start() {
        if isCancelled {
            debugPrint("\(name!) operation already cancelled! Skipped!")
            isFinished = true
            return
        }

        guard !isExecuting else {
            debugPrint("\(name!) operation already started! Skipped!")
            return
        }

        isReady = false
        isExecuting = true
        isFinished = false
        isCancelled = false
        isSuccess = false

        debugPrint("\(name!) operation started.")

        let queue = DispatchQueue(label: identifier, attributes: .concurrent)

        // NOTE: - Must to declare execution closures in reverse order

        // Call Response Interceptors
        let responseClosure: (Bool) -> Void = { [weak self] handleSuccess in
            queue.async { [weak self] in
                self?.performResponseInterceptors(completion: { [weak self] success in
                    guard let self = self else { return }

                    if handleSuccess {
                        self.isSuccess = success
                    }
                    self.finish()
                })
            }
        }

        // Call main execution
        let mainExecutionClosure = { [weak self] in
            queue.async { [weak self] in
                self?.main(completion: { [weak self] success in
                    self?.isSuccess = success
                    responseClosure(success)
                })
            }
        }

        // Call Request Interceptors
        queue.async { [weak self] in
            self?.performRequestInterceptors(completion: { [weak self] success in
                guard let self = self else { return }

                if success {
                    mainExecutionClosure()
                } else {
                    self.isSuccess = false

                    // We would like to run Response Interceptors too
                    responseClosure(false)
                }
            })
        }
    }

    open override func cancel() {
        debugPrint("\(name!) operation cancelled.")
        super.cancel()
    }

    open func performRequestInterceptors(completion: @escaping (Bool) -> Void) {
        assertionFailure("Implement this method in subclass, and don't call super!")
    }

    open func performResponseInterceptors(completion: @escaping (Bool) -> Void) {
        assertionFailure("Implement this method in subclass, and don't call super!")
    }
}

// MARK: - Sources

// http://szulctomasz.com/how-do-I-build-a-network-layer/
