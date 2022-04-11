//
//  PullToRefresh.swift
//  
//
//  Created by Dmitry Kononchuk on 11.02.2022.
//

import SwiftUI

struct PullToRefresh: UIViewRepresentable {
    // MARK: - Property Wrappers
    @Binding var isShowing: Bool
    
    // MARK: - Public Properties
    let deadline: Double
    let onRefresh: () -> Void
    
    // MARK: - Public Methods
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let viewHost = uiView.superview?.superview else { return }
        guard let tableView = tableView(root: viewHost) else { return }
        
        if let refreshControl = tableView.refreshControl {
            DispatchQueue.main.async {
                isShowing
                ? refreshControl.beginRefreshing()
                : refreshControl.endRefreshing()
            }
            
            return
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .white
        refreshControl.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefreshControl),
            for: .valueChanged
        )
        
        tableView.refreshControl = refreshControl
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isShowing: $isShowing, deadline: deadline, onRefresh: onRefresh)
    }
    
    // MARK: - Private Methods
    private func tableView(root: UIView) -> UITableView? {
        for subview in root.subviews {
            if let tableView = subview as? UITableView {
                return tableView
            } else if let tableView = tableView(root: subview) {
                return tableView
            }
        }
        
        return nil
    }
}

// MARK: - Ext. Coordinator
extension PullToRefresh {
    class Coordinator {
        // MARK: - Property Wrappers
        let isShowing: Binding<Bool>
        
        // MARK: - Public Properties
        let deadline: Double
        let onRefresh: () -> Void
        
        // MARK: - Initializers
        init(isShowing: Binding<Bool>, deadline: Double, onRefresh: @escaping () -> Void) {
            self.isShowing = isShowing
            self.deadline = deadline
            self.onRefresh = onRefresh
        }
        
        // MARK: - Public Methods
        @objc func handleRefreshControl() {
            isShowing.wrappedValue = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + deadline) {
                self.onRefresh()
            }
        }
    }
}

// MARK: - Ext. View
extension View {
    func pullToRefresh(isShowing: Binding<Bool>, deadline: Double = 1, onRefresh: @escaping () -> Void) -> some View {
        overlay(
            PullToRefresh(isShowing: isShowing, deadline: deadline, onRefresh: onRefresh)
                .frame(width: 0, height: 0)
        )
    }
}
