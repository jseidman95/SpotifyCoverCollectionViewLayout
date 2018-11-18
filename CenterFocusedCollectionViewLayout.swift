//
//  CenterFocusedCollectionViewLayout.swift
//  CenterFocusedCollectionView
//
//  Created by Jesse Seidman on 11/16/18.
//  Copyright © 2018 Jesse Seidman. All rights reserved.
//

import UIKit

class CenterFocusedCollectionViewLayout: UICollectionViewFlowLayout {
  // MARK: Public Properties
  var unfocusedItemSize: CGSize
  var focusedItemSize: CGSize
  var unfocusedItemAlpha: CGFloat
  override var minimumLineSpacing: CGFloat {
    get {
      return super.minimumLineSpacing - (focusedItemSize.width - unfocusedItemSize.width) / 2
    }
    set {
      super.minimumLineSpacing = newValue
    }
  }
  override var itemSize: CGSize {
    get {
      return focusedItemSize
    }
    set {
      self.focusedItemSize = newValue
    }
  }

  // MARK: Public Methods
  init(
    focusedItemSize: CGSize = CGSize.zero,
    unfocusedItemSize: CGSize = CGSize.zero,
    unfocusedItemAlpha: CGFloat = 1.0,
    minimumLineSpacing: CGFloat = 0
  ) {
    self.focusedItemSize = focusedItemSize
    self.unfocusedItemSize = unfocusedItemSize
    self.unfocusedItemAlpha = unfocusedItemAlpha
    super.init()
    self.minimumLineSpacing = minimumLineSpacing
    self.scrollDirection = .horizontal
  }
  

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepare() {
    guard let collectionView = collectionView else { return }
    let verticalInsets = (collectionView.frame.height - collectionView.adjustedContentInset.top - collectionView.adjustedContentInset.bottom - focusedItemSize.height) / 2
    let horizontalInsets = (collectionView.frame.width - collectionView.adjustedContentInset.right - collectionView.adjustedContentInset.left - focusedItemSize.width) / 2
    sectionInset = UIEdgeInsets(top: verticalInsets, left: horizontalInsets, bottom: verticalInsets, right: horizontalInsets)

    super.prepare()
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let collectionView = collectionView else { return nil }
    guard let currentAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
    let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)

    let activeDistance:CGFloat = focusedItemSize.width / 2 + minimumLineSpacing * 2

    for attributes in currentAttributes where attributes.frame.intersects(visibleRect) {
      let distance = visibleRect.midX - attributes.center.x
      let normalizedDistance = 1 - (distance / activeDistance).magnitude

      if distance.magnitude < activeDistance {
        attributes.alpha = unfocusedItemAlpha + normalizedDistance.magnitude * (1 - unfocusedItemAlpha)
        let width = unfocusedItemSize.width + (focusedItemSize.width - unfocusedItemSize.width) * normalizedDistance.magnitude
        let height = unfocusedItemSize.height + (focusedItemSize.height - unfocusedItemSize.height) * normalizedDistance.magnitude
        attributes.size = CGSize(width: width, height: height)
      } else {
        attributes.alpha = unfocusedItemAlpha
        attributes.size = unfocusedItemSize
      }
    }

    return currentAttributes
  }

  override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard let collectionView = self.collectionView else {
      return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }

    let collectionViewBounds = collectionView.bounds
    let collectionViewHalfWidth = collectionViewBounds.size.width * 0.5
    let proposedContentOffsetCenterX = proposedContentOffset.x + collectionViewHalfWidth

    if let attributesForVisibleCells = self.layoutAttributesForElements(in: collectionViewBounds) {
      var centerMostAttributes: UICollectionViewLayoutAttributes?
      for attributes in attributesForVisibleCells {
        // We only want to modify cells
        guard attributes.representedElementCategory == UICollectionView.ElementCategory.cell else { continue }

        if let centerAttributes = centerMostAttributes {
          centerMostAttributes = [centerAttributes, attributes].min { ($0.center.x - proposedContentOffsetCenterX).magnitude < ($1.center.x - proposedContentOffsetCenterX).magnitude }
        } else { // this is the first cell in the loop
          centerMostAttributes = attributes
          continue
        }
      }

      if let attributes = centerMostAttributes {
        return CGPoint(x: attributes.center.x - collectionViewHalfWidth, y: proposedContentOffset.y)
      }
    }

    return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }

  override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
    guard let context = super.invalidationContext(forBoundsChange: newBounds) as? UICollectionViewFlowLayoutInvalidationContext else { return UICollectionViewFlowLayoutInvalidationContext() }
    context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
    return context
  }
}
