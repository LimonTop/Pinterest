//
//  PinterestLayout.swift
//  Pinterest
//
//  Created by catch on 15/3/23.
//  Copyright (c) 2015年 Razeware LLC. All rights reserved.
//

import UIKit

protocol PinterestLayoutDelegate {

    func collectionView(collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat

}

// Ounce you have this subclass, you can then declare any custom properties
class PintersetLayoutAttributes: UICollectionViewLayoutAttributes {

    var photoHeight: CGFloat = 0.0


    // Because the CollectionView copies layoutAttributes as part of the layout process
    // 保证添加的 property 能够使用NSCopying 协议去创建一个 UICollectionView的副本传递给单元格
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = super.copyWithZone(zone) as! PintersetLayoutAttributes
        copy.photoHeight = photoHeight
        return copy
    }

    override func isEqual(object: AnyObject?) -> Bool {
        if let attributes = object as? PintersetLayoutAttributes {
            if attributes.photoHeight == photoHeight {
                return super.isEqual(object)
            }
        }
        return false
    }

}


class PinterestLayout: UICollectionViewLayout {

    var delegate: PinterestLayoutDelegate!
    var numberOfColumns = 1

    // 重点：cache是自定的UILayoutAttributes
    private var cache = [PintersetLayoutAttributes]()
    private var contentHeight: CGFloat = 0
    var cellPadding: CGFloat = 0
    private var width: CGFloat {
        get {
            let insets = collectionView!.contentInset
            return CGRectGetWidth(collectionView!.bounds) - (insets.left +
                insets.right)
        }
    }

    // tell the collectionView whenever it`s dispensing instances of the attributes to use our class instead of the standard class
    override class func layoutAttributesClass() -> AnyClass {
        return PintersetLayoutAttributes.self
    }

    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: width, height: contentHeight)
    }

    override func prepareLayout() {
        if cache.isEmpty {
            let columnWidth = width / CGFloat(numberOfColumns)
            var xOffsets = [CGFloat]()
            for column in 0..<numberOfColumns {
                xOffsets.append(CGFloat(column) * columnWidth)
            }
            var yOffsets = [CGFloat](count: numberOfColumns, repeatedValue: 0)
            var column = 0
            for item in 0..<collectionView!.numberOfItemsInSection(0) {
                let indexPath = NSIndexPath(forItem: item, inSection: 0)

                // 重点：从VC中获取自定义的宽高
                let width = columnWidth - (cellPadding * 2)
                let photoHeight = delegate.collectionView(collectionView!, heightForPhotoAtIndexPath: indexPath, withWidth: width)
                let annotationHeight = delegate.collectionView(collectionView!, heightForAnnotationAtIndexPath: indexPath, withWidth: width)
                let height = cellPadding + photoHeight + annotationHeight + cellPadding

                let frame = CGRect(x: xOffsets[column], y: yOffsets[column], width: columnWidth, height: height)
                let insetFrame = CGRectInset(frame, cellPadding, cellPadding)

                // 根据indexPath取出对应cell的attributes
                let attributes = PintersetLayoutAttributes(forCellWithIndexPath: indexPath)
                // 设置cell的attributes的frame
                attributes.frame = insetFrame
                attributes.photoHeight = photoHeight
                
                cache.append(attributes)
                contentHeight = max(contentHeight, CGRectGetMaxY(frame))
                yOffsets[column] = yOffsets[column] + height
                column = column >= (numberOfColumns - 1) ? 0 : ++column
            }

        }
    }

    // 返回cache中的attributes
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if CGRectIntersectsRect(attributes.frame, rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }

}
