//
//  CNCarLinkChargeDragCollectionViewLayout.swift
//  CNCarLink
//
//  Created by user on 2026/7/7.
//

import UIKit

/// layout自己不知道Cell高度、间距、inset因此需要定义协议来获取
protocol CNCarLinkChargeDragCollectionViewLayoutDelegate: AnyObject {
    func itemSize(at indexPath: IndexPath) -> CGSize
    
    func minimumLineSpacing() -> CGFloat
    
    func sectionInset() -> UIEdgeInsets
    
    func dragLayout(_ layout: CNCarLinkChargeDragCollectionViewLayout, moveItemAt source: IndexPath, to destination: IndexPath)
}

/// layout增加拖拽状态
struct CNCarLinkChargeDragState {
    /// 当前拖拽Cell
    var draggingIndexPath: IndexPath?

    /// 手指位置(CollectionView坐标系)
    var touchLocation: CGPoint = .zero

    /// Cell开始拖拽时Frame
    var originalFrame: CGRect = .zero

    /// 手指距离Cell左上角的偏移
    var touchOffset: CGPoint = .zero

    /// 是否正在拖拽
    var isDragging: Bool {
        draggingIndexPath != nil
    }
}

class CNCarLinkChargeDragCollectionViewLayout: UICollectionViewLayout {
    weak var delegate: CNCarLinkChargeDragCollectionViewLayoutDelegate?
    
    /// 缓存所有cell的attributes
    private var attributedsCache: [UICollectionViewLayoutAttributes] = []
    
    /// contentSize
    private var contentSize: CGSize = .zero
    
    
    private var dragState = CNCarLinkChargeDragState()
    
    /// 当前准备交换的目标位置
    private var targetIndexPath: IndexPath?
    
    
    private var previousTarget: IndexPath?
    
    /// 这是Layout最重要的方法
    /// 每一次: reloadData()、invalidateLayout()、旋转、Bounds变化都会调用
    override func prepare() {
        super.prepare()
        
        print("[C]layout: prepare()函数执行了")
        // 清空缓存
        attributedsCache.removeAll()
        
        guard let collectionView = collectionView else { return }
        
        let count = collectionView.numberOfItems(inSection: 0)
        
        let inset = delegate?.sectionInset() ?? .zero

        let spacing = delegate?.minimumLineSpacing() ?? 0
        
        var currentY = inset.top
        
        for item in 0..<count {
            let indexPath = IndexPath(item: item, section: 0)
            
            // 获取cell大小
            let size = delegate?.itemSize(at: indexPath) ?? .zero
            
            // 计算frame
            let frame = CGRect(x: inset.left, y: currentY, width: size.width, height: size.height)
            
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attr.frame = frame
            
            attributedsCache.append(attr)
            
            currentY += size.height
            currentY += spacing
            
            
        }
        
        contentSize = CGSize(width: collectionView.bounds.width, height: currentY - spacing + inset.bottom)
        
        
    }
    
    /// 返回contentSize
    override var collectionViewContentSize: CGSize {
        print("[C]layout: collectionViewContentSize属性被调用了")
        return contentSize
    }
    
    /// 当屏幕显示某一段rect的时候系统会调起该方法要求layout传入一些attributes
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        print("[C]layout: layoutAttributesForElements函数被调用了")
        
        var result: [UICollectionViewLayoutAttributes] = []
        for attribute in attributedsCache {
            // 注意: 以后永远不要直接修改缓存，修改copy
            guard let copy = attribute.copy() as? UICollectionViewLayoutAttributes else { continue }
            
            if copy.frame.intersects(rect) {
                result.append(copy)
            }
        }
        
        updateDraggingAttributes(result)
        return result
        
//        // 为什么filter，因为屏幕外不用返回
//        return attributedsCache.filter {
//            rect.intersects($0.frame)
//        }
    }
    
    private func updateDraggingAttributes(_ attributes: [UICollectionViewLayoutAttributes]) {

        guard dragState.isDragging else {
            return
        }

        for attribute in attributes {

            guard attribute.indexPath == dragState.draggingIndexPath else {
                continue
            }

            var frame = dragState.originalFrame

            frame.origin.y = dragState.touchLocation.y - dragState.touchOffset.y

            attribute.frame = frame

            attribute.zIndex = 999

            attribute.transform = CGAffineTransform(scaleX: 1.03,
                                                    y: 1.03)

            attribute.alpha = 0.95
        }

    }
    
    /// 单独返回某个cell
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        print("[C]layout: layoutAttributesForItem函数被调用了")
        return attributedsCache.first { attr in
            attr.indexPath == indexPath
        }
    }
    
    /// Bounds变化，为什么返回false，因为目前没有拖拽所以不用重新布局
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
//        print("[C]layout: shouldInvalidateLayout函数被调用了")
        return dragState.isDragging
    }
    
    func beginDrag(at indexPath: IndexPath, location: CGPoint, cell: UICollectionViewCell) {

        dragState.draggingIndexPath = indexPath

        dragState.touchLocation = location

        dragState.originalFrame = cell.frame

        dragState.touchOffset = CGPoint(
            x: location.x - cell.frame.minX,
            y: location.y - cell.frame.minY
        )

        invalidateLayout()
    }
    
    func updateDrag(location: CGPoint) {

        guard dragState.isDragging else {
            return
        }

        dragState.touchLocation = location
        
        updateTargetIndex()
        print("[C]layout: 目标索引位置 - \(targetIndexPath?.item ?? 0)")

        invalidateLayout()
    }
    
    func endDrag() {

        dragState = CNCarLinkChargeDragState()
        
        targetIndexPath = nil
        previousTarget = nil

        invalidateLayout()
    }
    
    func updateDraggingIndexPath(_ indexPath: IndexPath) {
        dragState.draggingIndexPath = indexPath
        
        if let attr = attributedsCache.first(where: {$0.indexPath == indexPath}) {
            dragState.originalFrame = attr.frame
        }
        
        previousTarget = nil
    }
    
    private func updateTargetIndex() {
        guard let dragging = dragState.draggingIndexPath else { return }
        
        // 得到拖拽cell当前位置frame
        let dragFrame = CGRect(

            x: dragState.originalFrame.origin.x,

            y: dragState.touchLocation.y - dragState.touchOffset.y,

            width: dragState.originalFrame.width,

            height: dragState.originalFrame.height

        )
        
        // 得到拖拽cell的中心点Y值
        let dragCenterY = dragFrame.midY
        
        let currentAttr = attributedsCache[dragging.item]
        
        // 判断拖动方向
        let isMoveDown = dragCenterY > currentAttr.center.y
        
        let next = dragging.item + 1

        if isMoveDown {

            // 只判断下一个Cell
            let next = dragging.item + 1

            if next < attributedsCache.count {

                let nextAttr = attributedsCache[next]

                if dragCenterY > nextAttr.center.y {
                    targetIndexPath = nextAttr.indexPath
                }
            }

        } else {

            // 只判断上一个Cell
            let previous = dragging.item - 1

            if previous >= 0 {

                let previousAttr = attributedsCache[previous]

                if dragCenterY < previousAttr.center.y {
                    targetIndexPath = previousAttr.indexPath
                }
            }
        }
//        for attr in attributedsCache {
//            // 跳过被拖拽的cell自己
//            guard attr.indexPath != dragging else {
//                continue
//            }
//
//            // 比较向下拖动时
//            if dragCenterY > attr.center.y {
//                targetIndexPath = attr.indexPath
//            }
//        }
        
        guard let targetIndexPath else { return }
        
        // 避免自己和自己交换
        guard targetIndexPath != dragging else {
            return
        }
        
        // 例如一直停在B，不要每一帧都swap，只交换一次
        guard targetIndexPath != previousTarget else {
            return
        }
        
        previousTarget = targetIndexPath
        
        // 通知vc
        delegate?.dragLayout(self, moveItemAt: dragging, to: targetIndexPath)
    }
}


