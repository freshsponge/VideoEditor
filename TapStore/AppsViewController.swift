//
//  ViewController.swift
//  TapStore
//
//  Created by Paul Hudson on 01/10/2019.
//  Copyright © 2019 Hacking with Swift. All rights reserved.
//

import Photos
import PhotosUI
import UIKit
import AVKit

class AppsViewController: UIViewController {
    
    var controller = AVPlayerViewController()
    
    let sections = Bundle.main.decode([Section].self, from: "videoGraphics.json")
    var collectionView: UICollectionView!

    var dataSource: UICollectionViewDiffableDataSource<Section, App>?

    private var selection = [String: PHPickerResult]()
    private var selectedAssetIdentifiers = [String]()
    private var selectedAssetIdentifierIterator: IndexingIterator<[String]>?
    private var currentAssetIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapClose))

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createCompositionalLayout())
        
//        for collectionView in [inProgressCollectionView, completedCollectionView] {
//          if let collectionView = collectionView {
//            collectionView.dataSource = dataSourceForCollectionView(collectionView)
//            collectionView.delegate = self
//            collectionView.dragDelegate = self
//            collectionView.dropDelegate = self
//          }
//        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 600),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
            
//        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]


//        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.reuseIdentifier)
        collectionView.register(FeaturedCell.self, forCellWithReuseIdentifier: FeaturedCell.reuseIdentifier)
//        collectionView.register(MediumTableCell.self, forCellWithReuseIdentifier: MediumTableCell.reuseIdentifier)
//        collectionView.register(SmallTableCell.self, forCellWithReuseIdentifier: SmallTableCell.reuseIdentifier)

        createDataSource()
        reloadData()
    }
    
    @objc private func didTapAdd() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 3
        config.filter = .videos
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @objc private func didTapClose() {
        controller.view.removeFromSuperview()
        print("tapped close")
    }
         
    // add in video player code from other PHPicker created from 2020 WWDC
    
//    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//        picker.dismiss(animated: true, completion: nil)
//
//        results.forEach { result in
//            result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
//                guard let image = reading as? UIImage, error == nil else{
//                    return
//                }
//                print(image)
//            }
//        }
//    }
            

    func configure<T: SelfConfiguringCell>(_ cellType: T.Type, with app: App, for indexPath: IndexPath) -> T {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Unable to dequeue \(cellType)")
        }

        cell.configure(with: app)
        return cell
    }

    func createDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, App>(collectionView: collectionView) { collectionView, indexPath, app in
            switch self.sections[indexPath.section].type {
//            case "mediumTable":
//                return self.configure(MediumTableCell.self, with: app, for: indexPath)
//            case "smallTable":
//                return self.configure(SmallTableCell.self, with: app, for: indexPath)
            default:
                return self.configure(FeaturedCell.self, with: app, for: indexPath)
            }
        }

        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeader.reuseIdentifier, for: indexPath) as? SectionHeader else {
                return nil
            }

            guard let firstApp = self?.dataSource?.itemIdentifier(for: indexPath) else { return nil }
            guard let section = self?.dataSource?.snapshot().sectionIdentifier(containingItem: firstApp) else { return nil }
            if section.title.isEmpty { return nil }

            sectionHeader.title.text = section.title
            sectionHeader.subtitle.text = section.subtitle
            return sectionHeader
        }
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, App>()
        snapshot.appendSections(sections)

        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
        }

        dataSource?.apply(snapshot)
    }

    func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let section = self.sections[sectionIndex]

            switch section.type {
//            case "mediumTable":
//                return self.createMediumTableSection(using: section)
//            case "smallTable":
//                return self.createSmallTableSection(using: section)
            default:
                return self.createFeaturedSection(using: section)
            }
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        layout.configuration = config
        return layout
    }

    func createFeaturedSection(using section: Section) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(0.5))

        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.93), heightDimension: .estimated(350))
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: layoutGroupSize, subitems: [layoutItem])

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
        return layoutSection
    }

//    func createMediumTableSection(using section: Section) -> NSCollectionLayoutSection {
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.33))
//
//        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
//        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
//
//        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.93), heightDimension: .fractionalWidth(0.55))
//        let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: layoutGroupSize, subitems: [layoutItem])
//
//        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
//        layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
//
//        let layoutSectionHeader = createSectionHeader()
//        layoutSection.boundarySupplementaryItems = [layoutSectionHeader]
//
//        return layoutSection
//    }
//
//    func createSmallTableSection(using section: Section) -> NSCollectionLayoutSection {
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.2))
//        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
//        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)
//
//        let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.93), heightDimension: .estimated(200))
//        let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: layoutGroupSize, subitems: [layoutItem])
//
//        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
//        let layoutSectionHeader = createSectionHeader()
//        layoutSection.boundarySupplementaryItems = [layoutSectionHeader]
//
//        return layoutSection
//    }

    func createSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let layoutSectionHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.93), heightDimension: .estimated(80))
        let layoutSectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: layoutSectionHeaderSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return layoutSectionHeader
    }
}

private extension AppsViewController {
    
    /// - Tag: LoadItemProvider
    func displayNext() {
        guard let assetIdentifier = selectedAssetIdentifierIterator?.next() else { return }
        currentAssetIdentifier = assetIdentifier
        
        let progress: Progress?
        let itemProvider = selection[assetIdentifier]!.itemProvider
        if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
            progress = itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                DispatchQueue.main.async {
                    self?.handleCompletion(assetIdentifier: assetIdentifier, object: livePhoto, error: error)
                }
            }
        }
        else if itemProvider.canLoadObject(ofClass: UIImage.self) {
            progress = itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    self?.handleCompletion(assetIdentifier: assetIdentifier, object: image, error: error)
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            progress = itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                do {
                    guard let url = url, error == nil else {
                        throw error ?? NSError(domain: NSFileProviderErrorDomain, code: -1, userInfo: nil)
                    }
                    let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.removeItem(at: localURL)
                    try FileManager.default.copyItem(at: url, to: localURL)
                    DispatchQueue.main.async {
                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: localURL)
                    }
                } catch let catchedError {
                    DispatchQueue.main.async {
                        self?.handleCompletion(assetIdentifier: assetIdentifier, object: nil, error: catchedError)
                    }
                }
            }
        } else {
            progress = nil
        }

    }
    
    func handleCompletion(assetIdentifier: String, object: Any?, error: Error? = nil) {
        guard currentAssetIdentifier == assetIdentifier else { return }
            if let url = object as? URL {
            let player = AVPlayer(url: url)
//            let controller = AVPlayerViewController()
            controller.player = player
            self.addChild(controller)
            let screenSize = UIScreen.main.bounds.size
            let videoFrame = CGRect(x: 0, y: 100, width: screenSize.width, height: (screenSize.height - 10) * 0.5)
            controller.view.frame = videoFrame
            self.view.addSubview(controller.view)
//                controller.view.removeFromSuperview()
            player.play()
        } else if let error = error {
            print("Couldn't display \(assetIdentifier) with error: \(error)")
            displayErrorImage()
        } else {
            displayUnknownImage()
        }
        
    }
    
}



//extension AVPlayerViewController {
//    func dismissVideo() {
//        let dissmissButton = UIButton(type: .close)
//        dissmissButton.titleLabel
        
//        self.view.willRemoveSubview(controller.view)
//    }
//}

extension AppsViewController: PHPickerViewControllerDelegate {
    /// - Tag: ParsePickerResults
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        let existingSelection = self.selection
        var newSelection = [String: PHPickerResult]()
        for result in results {
            let identifier = result.assetIdentifier!
            newSelection[identifier] = existingSelection[identifier] ?? result
        }
        
        // Track the selection in case the user deselects it later.
        selection = newSelection
        selectedAssetIdentifiers = results.map(\.assetIdentifier!)
        selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()
        
        if selection.isEmpty {
            displayEmptyImage()
        } else {
            displayNext()
            print("Test")
        }
    }
}

private extension AppsViewController {
    
    func displayEmptyImage() {
        displayImage(UIImage(systemName: "photo.on.rectangle.angled"))
    }
    
    func displayErrorImage() {
        displayImage(UIImage(systemName: "exclamationmark.circle"))
    }
    
    func displayUnknownImage() {
        displayImage(UIImage(systemName: "questionmark.circle"))
    }
    
    func displayImage(_ video: UIImage?) {
     
    }
}
//
//extension AppsViewController: UIDragInteractionDelegate, UIDropInteractionDelegate {
//
//}

//extension AppsViewController {
//  func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
//    let dragSection = sections[indexPath.item]
//    let itemProvider = NSItemProvider(object: dragSection.name as NSString)
//    let dragItem = UIDragItem(itemProvider: itemProvider)
//    return [dragItem]
//  }
//}
//
//extension AppsViewController: UICollectionViewDragDelegate {
//  func collectionView(_ collectionView: UICollectionView,
//                      itemsForBeginning session: UIDragSession,
//                      at indexPath: IndexPath) -> [UIDragItem] {
//    let dataSource = dataSourceForCollectionView(collectionView)
//    return dataSource.dragItems(for: indexPath)
//  }
//}


