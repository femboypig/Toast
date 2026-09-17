import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils

final class ToastSliderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let title: String
    let valueText: String
    let minValue: Float
    let maxValue: Float
    let value: Float
    let sectionId: ItemListSectionId
    let updated: (Float) -> Void

    init(
        presentationData: ItemListPresentationData,
        title: String,
        valueText: String,
        minValue: Float,
        maxValue: Float,
        value: Float,
        sectionId: ItemListSectionId,
        updated: @escaping (Float) -> Void
    ) {
        self.presentationData = presentationData
        self.title = title
        self.valueText = valueText
        self.minValue = minValue
        self.maxValue = maxValue
        self.value = value
        self.sectionId = sectionId
        self.updated = updated
    }

    func nodeConfiguredForParams(
        async: @escaping (@escaping () -> Void) -> Void,
        params: ListViewItemLayoutParams,
        synchronousLoads: Bool,
        previousItem: ListViewItem?,
        nextItem: ListViewItem?,
        completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void
    ) {
        async {
            let node = ToastSliderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    func updateNode(
        async: @escaping (@escaping () -> Void) -> Void,
        node: @escaping () -> ListViewItemNode,
        params: ListViewItemLayoutParams,
        previousItem: ListViewItem?,
        nextItem: ListViewItem?,
        animation: ListViewItemUpdateAnimation,
        completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void
    ) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ToastSliderItemNode {
                let makeLayout = nodeValue.asyncLayout()
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in apply() })
                    }
                }
            }
        }
    }
}

private final class ToastSliderItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    private let titleNode: TextNode
    private let valueNode: TextNode
    private var sliderView: UISlider?
    private var item: ToastSliderItem?

    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true

        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true

        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true

        self.maskNode = ASImageNode()

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false

        self.valueNode = TextNode()
        self.valueNode.isUserInteractionEnabled = false

        super.init(layerBacked: false)
    }

    func asyncLayout() -> (_ item: ToastSliderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeValueLayout = TextNode.asyncLayout(self.valueNode)

        return { [weak self] item, params, neighbors in
            let theme = item.presentationData.theme
            let titleFont = Font.regular(item.presentationData.fontSize.itemListBaseFontSize)
            let valueFont = Font.regular(item.presentationData.fontSize.itemListBaseFontSize)

            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(
                attributedString: NSAttributedString(string: item.title, font: titleFont, textColor: theme.list.itemPrimaryTextColor),
                backgroundColor: nil,
                maximumNumberOfLines: 1,
                truncationType: .end,
                constrainedSize: CGSize(width: max(0.0, params.width - params.leftInset - params.rightInset - 120.0), height: CGFloat.greatestFiniteMagnitude)
            ))

            let (valueLayout, valueApply) = makeValueLayout(TextNodeLayoutArguments(
                attributedString: NSAttributedString(string: item.valueText, font: valueFont, textColor: theme.list.itemAccentColor),
                backgroundColor: nil,
                maximumNumberOfLines: 1,
                truncationType: .end,
                constrainedSize: CGSize(width: 120.0, height: CGFloat.greatestFiniteMagnitude)
            ))

            let contentSize = CGSize(width: params.width, height: 78.0)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let separatorHeight = UIScreenPixel

            return (layout, {
                guard let strongSelf = self else { return }
                strongSelf.item = item

                strongSelf.backgroundNode.backgroundColor = theme.list.itemBlocksBackgroundColor
                strongSelf.topStripeNode.backgroundColor = theme.list.itemBlocksSeparatorColor
                strongSelf.bottomStripeNode.backgroundColor = theme.list.itemBlocksSeparatorColor

                if strongSelf.backgroundNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                }
                if strongSelf.topStripeNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                }
                if strongSelf.bottomStripeNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                }
                if strongSelf.maskNode.supernode == nil {
                    strongSelf.insertSubnode(strongSelf.maskNode, at: 3)
                }
                if strongSelf.titleNode.supernode == nil {
                    strongSelf.addSubnode(strongSelf.titleNode)
                }
                if strongSelf.valueNode.supernode == nil {
                    strongSelf.addSubnode(strongSelf.valueNode)
                }

                let _ = titleApply()
                let _ = valueApply()

                let hasCorners = itemListHasRoundedBlockLayout(params)
                var hasTopCorners = false
                var hasBottomCorners = false
                switch neighbors.top {
                case .sameSection(false):
                    strongSelf.topStripeNode.isHidden = true
                default:
                    hasTopCorners = true
                    strongSelf.topStripeNode.isHidden = hasCorners
                }
                let bottomStripeInset: CGFloat
                let bottomStripeOffset: CGFloat
                switch neighbors.bottom {
                case .sameSection(false):
                    bottomStripeInset = params.leftInset + 16.0
                    bottomStripeOffset = -separatorHeight
                    strongSelf.bottomStripeNode.isHidden = false
                default:
                    bottomStripeInset = 0.0
                    bottomStripeOffset = 0.0
                    hasBottomCorners = true
                    strongSelf.bottomStripeNode.isHidden = hasCorners
                }

                strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(theme, top: hasTopCorners, bottom: hasBottomCorners) : nil

                strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                strongSelf.maskNode.frame = strongSelf.backgroundNode.frame.insetBy(dx: params.leftInset, dy: 0.0)
                strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layout.size.width, height: separatorHeight))
                strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layout.size.width - bottomStripeInset - params.rightInset, height: separatorHeight))

                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: params.leftInset + 16.0, y: 12.0), size: titleLayout.size)
                strongSelf.valueNode.frame = CGRect(origin: CGPoint(x: params.width - params.rightInset - 16.0 - valueLayout.size.width, y: 12.0), size: valueLayout.size)

                let sliderView: UISlider
                if let current = strongSelf.sliderView {
                    sliderView = current
                } else {
                    let created = UISlider()
                    created.addTarget(strongSelf, action: #selector(strongSelf.sliderChanged(_:)), for: .valueChanged)
                    strongSelf.view.addSubview(created)
                    strongSelf.sliderView = created
                    sliderView = created
                }

                sliderView.minimumValue = item.minValue
                sliderView.maximumValue = item.maxValue
                if !sliderView.isTracking {
                    sliderView.value = item.value
                }
                sliderView.minimumTrackTintColor = theme.list.itemAccentColor
                sliderView.maximumTrackTintColor = theme.list.itemSwitchColors.frameColor

                sliderView.frame = CGRect(
                    x: params.leftInset + 16.0,
                    y: 38.0,
                    width: max(0.0, params.width - params.leftInset - params.rightInset - 32.0),
                    height: 32.0
                )
            })
        }
    }

    @objc private func sliderChanged(_ sender: UISlider) {
        self.item?.updated(sender.value)
    }
}
