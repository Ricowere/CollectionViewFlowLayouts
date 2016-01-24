// StickyHeaderCollectionViewFlowLayout
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

@objc protocol DRNStickyHeaderCollectionViewDelegateFlowLayout : UICollectionViewDelegateFlowLayout {
    
    optional func collectionViewReferenceSizeForStickyHeader(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> CGSize
    
}

@objc(DRNStickyHeaderCollectionViewFlowLayout)
class StickyHeaderCollectionViewFlowLayout : UICollectionViewFlowLayout {
    
    private let kDRNStickyHeaderCollectionViewIdentifier = "__kDRNStickyHeaderCollectionViewIdentifier"
    static let kDRNStickyHeaderCollectionViewIdentifier = "__kDRNStickyHeaderCollectionViewIdentifier"
    
    /**
    *  Reference size for the stickyHeader placed on top. If stickyHeaderReferenceSize is not defined,
    * the default collectionView.bounds.size.width is setted for the size width and height.
    */
    @IBInspectable
    var stickyHeaderReferenceSize: CGSize = CGSizeZero
    
    private var _stickyHeaderReferenceSize: CGSize {
    
        get {
            guard let uwpCollectionView = collectionView else {
                return CGSizeZero
            }
            
            if let delegate = uwpCollectionView.delegate as? DRNStickyHeaderCollectionViewDelegateFlowLayout  where delegate.respondsToSelector("collectionViewReferenceSizeForStickyHeader:layout:") {
                
                return delegate.collectionViewReferenceSizeForStickyHeader!(uwpCollectionView, layout: self)
            }
            return stickyHeaderReferenceSize
        }
    }
    
    override init() {
        super.init()
        
        registerClass(SimulatedBackgroundDecorationView.self, forDecorationViewOfKind: kDRNSimulatedBackgroundInterlayerDecorationView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        registerClass(SimulatedBackgroundDecorationView.self, forDecorationViewOfKind: kDRNSimulatedBackgroundInterlayerDecorationView)
    }
    
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    
    override func collectionViewContentSize() -> CGSize {
        
        let currentContentSize = super.collectionViewContentSize()
        
        guard let uwpCollectionView = collectionView else {
            fatalError()
        }
        
        let extendedContentSizeHeight = currentContentSize.height + _stickyHeaderReferenceSize.height - uwpCollectionView.contentInset.top + expandCollectionViewContentSize(currentContentSize)
        
        return CGSizeMake(currentContentSize.width, extendedContentSizeHeight);
    }
    
    
    func expandCollectionViewContentSize(currentContentSize: CGSize) -> CGFloat {
        guard let uwpCollectionView = collectionView else {
            fatalError()
        }
        
        let contentInsetHeight = uwpCollectionView.contentInset.top + uwpCollectionView.contentInset.bottom;
        let contentSizeHeight = uwpCollectionView.frame.size.height - contentInsetHeight;
        let contentOffsetSizeHeight = contentSizeHeight - currentContentSize.height;
        
        if (contentOffsetSizeHeight < 0) { return 0 }
        
        return contentOffsetSizeHeight;
    }
    
    
    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        if elementKind == kDRNSimulatedBackgroundInterlayerDecorationView {
            return UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
        }
        
        return nil
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {

        if let uwpLayoutAttribute = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath) {
            
            if elementKind != kDRNStickyHeaderCollectionViewIdentifier {
                uwpLayoutAttribute.zIndex = 10;
                return uwpLayoutAttribute;
            }
        }
        
        let layoutAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
        
        return layoutAttribute
    }
    
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let uwpLayoutAttributes = super.layoutAttributesForItemAtIndexPath(indexPath) else {
            return nil
        }
        
        uwpLayoutAttributes.zIndex = 10
        
        return uwpLayoutAttributes
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var adjustedRect = rect
        adjustedRect.origin.y -= _stickyHeaderReferenceSize.height
        adjustedRect.size.height += _stickyHeaderReferenceSize.height
        
        guard var uwpAttributes = super.layoutAttributesForElementsInRect(adjustedRect),
              let uwpCollectionView = collectionView else {
            return nil
        }
        
        var originYInterLayer: CGFloat = 0
        
        uwpAttributes = uwpAttributes.map { layoutAttributes in
            let layoutAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
            
            var newFrame = layoutAttributes.frame;
            newFrame.origin.y += _stickyHeaderReferenceSize.height - uwpCollectionView.contentInset.top;
            layoutAttributes.frame = newFrame;
            
            layoutAttributes.zIndex = 10;
            
            if (layoutAttributes.indexPath.item == 0) {
                originYInterLayer = max(uwpCollectionView.bounds.origin.y, layoutAttributes.frame.origin.y);
            }
            
            return layoutAttributes
        }
        
        if let stickyHeaderLayoutAttributes = layoutAttributesForStickyHeaderView() where CGRectIntersectsRect(rect, stickyHeaderLayoutAttributes.frame) {
            
            uwpAttributes.append(stickyHeaderLayoutAttributes)
        }
        
        
        if let interlayer = layoutAttributesForDecorationViewOfKind(kDRNSimulatedBackgroundInterlayerDecorationView, atIndexPath: NSIndexPath(index: 0)) {
        
            let rectForInterlayer = CGRectMake(0,
                originYInterLayer,
                uwpCollectionView.bounds.size.width,
                uwpCollectionView.bounds.size.height - originYInterLayer + uwpCollectionView.bounds.origin.y);
            
            interlayer.frame = rectForInterlayer;
            interlayer.zIndex = 1;
            
            uwpAttributes.append(interlayer)
        }
        
        return uwpAttributes
    }
    
    func layoutAttributesForStickyHeaderView() -> UICollectionViewLayoutAttributes? {
        
        guard let uwpAttributes = layoutAttributesForSupplementaryViewOfKind(self.kDRNStickyHeaderCollectionViewIdentifier, atIndexPath: NSIndexPath(index: 0)),
            let uwpCollectionView = collectionView else {

                return nil
        }
        
        let offsetY = uwpCollectionView.contentOffset.y;
        let topInset = uwpCollectionView.contentInset.top;
        
        let maxHeight = max(_stickyHeaderReferenceSize.height, _stickyHeaderReferenceSize.height - offsetY - topInset);
        let originX = (_stickyHeaderReferenceSize.height - maxHeight)/2;
        
        uwpAttributes.frame = CGRectMake(originX, uwpCollectionView.bounds.origin.y, maxHeight, maxHeight);
        uwpAttributes.zIndex = 0;
        
        return uwpAttributes;
    }
}


private let kDRNSimulatedBackgroundInterlayerDecorationView = "__kDRNSimulatedBackgroundInterlayerDecorationView"

@objc(DRNSimulatedBackgroundDecorationView)
private class SimulatedBackgroundDecorationView : UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = .whiteColor()
    }
}
