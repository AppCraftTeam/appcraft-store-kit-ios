//
//  SubscriptionsViewController.swift
//  acsorekit_demo@tester.com
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import ACStorekit
import UIKit

final class SubscriptionsViewController: UIViewController {
    
    private var model: SubscriptionsViewModel = SubscriptionsViewModel()
    
    // MARK: - UI components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    private lazy var purchaseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Purchase", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18.0, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(purchaseButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var restoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Restore purchases", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .regular)
        button.backgroundColor = .clear
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(restoreButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tintColor = .systemBlue
        view.hidesWhenStopped = true
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "ACStorekitDemo"
        self.view.backgroundColor = .systemGroupedBackground
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
        
        self.view.addSubview(tableView)
        self.view.addSubview(purchaseButton)
        self.view.addSubview(restoreButton)
        self.view.addSubview(indicatorView)
        
        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            purchaseButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            purchaseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            purchaseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            purchaseButton.heightAnchor.constraint(equalToConstant: 50),
            
            restoreButton.topAnchor.constraint(equalTo: purchaseButton.bottomAnchor, constant: 16),
            restoreButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            restoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            restoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            restoreButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        self.model.didProductsLoaded = { [weak self] in
            self?.tableView.reloadData()
        }
        
        self.model.didBeginLoading = { [weak self] in
            self?.setLoadingState(isLoading: true)
        }
        
        self.model.didStopLoading = { [weak self] in
            self?.setLoadingState(isLoading: false)
        }
        
        self.model.reload()
        self.purchaseButton.isUserInteractionEnabled = model.selectedProduct != nil
    }
}

// MARK: - Module
private extension SubscriptionsViewController {
    
    func setLoadingState(isLoading: Bool) {
        self.purchaseButton.isUserInteractionEnabled = !isLoading
        self.restoreButton.isUserInteractionEnabled = !isLoading
        self.tableView.isUserInteractionEnabled = !isLoading
        
        isLoading ? self.indicatorView.startAnimating() : self.indicatorView.stopAnimating()
    }
}

// MARK: - Actions
private extension SubscriptionsViewController {
    
    @objc
    func purchaseButtonTapped() {
        if let product = model.selectedProduct {
            setLoadingState(isLoading: true)
            model.purchaseService.purchase(product.skProduct)
        }
    }
    
    @objc
    func restoreButtonTapped() {
        setLoadingState(isLoading: true)
        model.purchaseService.restore()
    }
}

// MARK: - UITableViewDataSource
extension SubscriptionsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.purchaseService.products.filter({ $0.skProduct.isSubscription }).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.selectionStyle = .none
        
        let product = model.purchaseService.products[indexPath.row]
        
        let isSelected = model.selectedProduct?.product.productIdentifer ==  product.product.productIdentifer
        cell.accessoryType = isSelected ? .checkmark : .none
        cell.textLabel?.text = product.product.name
        cell.detailTextLabel?.text = product.skProduct.priceDefaultString
        cell.detailTextLabel?.textColor = .gray
        cell.detailTextLabel?.numberOfLines = 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = model.purchaseService.products[indexPath.row]
        model.selectedProduct = product
        purchaseButton.isUserInteractionEnabled = model.selectedProduct != nil
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Subscription products"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let activeProducts = model.purchaseService.products.getActiveProducts()
        if activeProducts.isEmpty {
            return nil
        }
        let activeProductsInfoText = activeProducts.map({ $0.skProduct.productIdentifier + ": \(String(describing: $0.expiresDate))" }).joined(separator: ", ")
        return "Active subscription: \(activeProductsInfoText)"
    }
}

// MARK: - UITableViewDataSource
extension SubscriptionsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
