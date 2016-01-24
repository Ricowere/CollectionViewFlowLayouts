// CollectionViewFlowLayoutLineal
// Copyright (c) 2016 David Rico
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

@objc(DRNCollectionViewFlowLayoutLineal)
class CollectionViewFlowLayoutLineal : UICollectionViewFlowLayout {
    
    @IBInspectable
    var zoomFactorActiveItem: CGFloat = 1
    
    @IBInspectable
    var alphaFactorNonActiveItems: CGFloat = 1
    

    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var uwpAttributes = super.layoutAttributesForElementsInRect(rect),
              let uwpCollectionView = collectionView else {
            return nil
        }
        
        var visibleRect = CGRectZero
        visibleRect.origin = uwpCollectionView.contentOffset
        visibleRect.size = uwpCollectionView.bounds.size
        
        uwpAttributes = uwpAttributes.map { attributeLayout in
            let attributeLayout = attributeLayout.copy() as! UICollectionViewLayoutAttributes
            
            let distance = distanceForVisibleRect(visibleRect: visibleRect,
                attributeLayout: attributeLayout)
            let normalizedDistance = normalizedDistanceForDistance(distance)
            
            if CGRectIntersectsRect(attributeLayout.frame, rect) {
                applyAttributesLayoutProperties(attributeLayout, distance: distance, normalizedDistance: normalizedDistance)
            }
            
            return attributeLayout
        }
        
        return uwpAttributes
    }
    
    
    func distanceForVisibleRect(visibleRect rect : CGRect,
        attributeLayout: UICollectionViewLayoutAttributes) -> CGFloat {
            
            switch scrollDirection {
                case .Vertical: return CGRectGetMidX(rect) - attributeLayout.center.y
                case .Horizontal: return CGRectGetMidX(rect) - attributeLayout.center.x
            }
    }
    
    
    func normalizedDistanceForDistance(distance: CGFloat) -> CGFloat {
        return distance / itemSizeForScrollDirection()
    }
    
    
    func itemSizeForScrollDirection() -> CGFloat {
        switch scrollDirection {
            case .Vertical: return itemSize.height
            case .Horizontal: return itemSize.width
        }
    }

    
    func itemCenterCoordinate(layoutAttribute: UICollectionViewLayoutAttributes) -> CGFloat {
        switch scrollDirection {
            case .Vertical: return layoutAttribute.center.y
            case .Horizontal: return layoutAttribute.center.x
        }
    }

    
    func applyAttributesLayoutProperties(attributeLayout: UICollectionViewLayoutAttributes, distance: CGFloat, normalizedDistance: CGFloat) {
        
        if abs(distance) < itemSizeForScrollDirection() {
            let zoom = 1 + zoomFactorActiveItem * (1 - abs(normalizedDistance))
            attributeLayout.transform3D = CATransform3DMakeScale(zoom, zoom, 1.0)
            attributeLayout.zIndex = lround(Double(zoom));
        }
        
        let alpha = 1 - ((1 - alphaFactorNonActiveItems) * abs(normalizedDistance))
        attributeLayout.alpha = alpha
    }

    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        var offsetAdjustment = CGFloat.max
        let centerCoordinate = centerForCurrentScrollDirectionWithProposedContentOffset(proposedContentOffset)
        let targetRect = targetRectForCurrentScrollDirectionWithProposedContentOffset(proposedContentOffset)
        
        guard let attributes = super.layoutAttributesForElementsInRect(targetRect) else {
            return CGPointZero
        }
        
        for layoutAttribute in attributes {
            let itemCenterCoordinateValue = itemCenterCoordinate(layoutAttribute)
            
            if abs(itemCenterCoordinateValue - centerCoordinate) < abs(offsetAdjustment) {
                offsetAdjustment = itemCenterCoordinateValue - centerCoordinate;
            }
        }
        
        return CGPointMake(offsetAdjustment, proposedContentOffset.y + offsetAdjustment);
    }

    
    func centerForCurrentScrollDirectionWithProposedContentOffset(proposedContentOffset: CGPoint) -> CGFloat {
        var contentOffsetCoordinate: CGFloat = 0;
        var boundSize: CGFloat = 0;
        
        guard let uwpCollectionView = collectionView else {
            fatalError()
        }
        
        switch scrollDirection {
            case .Vertical:
                contentOffsetCoordinate = proposedContentOffset.y
                boundSize = CGRectGetHeight(uwpCollectionView.bounds)
            
            case .Horizontal:
                contentOffsetCoordinate = proposedContentOffset.x;
                boundSize = CGRectGetWidth(uwpCollectionView.bounds);
        }
        
        return contentOffsetCoordinate + (boundSize / 2)
    }
    
    
    func targetRectForCurrentScrollDirectionWithProposedContentOffset(proposedContentOffset: CGPoint) -> CGRect {
        guard let uwpCollectionView = collectionView else {
            fatalError()
        }
        
        switch scrollDirection {
        case .Vertical: return CGRectMake(0, proposedContentOffset.y, uwpCollectionView.bounds.size.width, uwpCollectionView.bounds.size.height)
            
        case .Horizontal: return CGRectMake(proposedContentOffset.x, 0, uwpCollectionView.bounds.size.width, uwpCollectionView.bounds.size.height);
        }
    }
    
}