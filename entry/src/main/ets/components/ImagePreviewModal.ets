/**
 * ImagePreviewModal - 图片预览弹窗
 * 支持全屏预览图片，支持缩放和关闭
 */
import { UIStyle, PrimaryTextColorMap, SecondaryTextColorMap, PageBackgroundMap } from '../constants/UIStyleConst'

@CustomDialog
export struct ImagePreviewModal {
  controller: CustomDialogController

  // ==================== 全局风格监听 ====================
  @StorageProp('currentStyle') currentStyle: string = UIStyle.Minimalist

  // ==================== 图片数据 ====================
  @State imageUri: string = ''
  @State imageWidth: number = 0
  @State imageHeight: number = 0
  @State scaleValue: number = 1.0

  // ==================== build 方法 ====================
  build() {
    Column() {
      // ---- 顶部关闭按钮 ----
      Row() {
        Blank()

        Text('✕')
          .fontSize(24)
          .fontColor(Color.White)
          .padding(12)
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

      // ---- 图片展示区 ----
      Column() {
        if (this.imageUri !== '') {
          Image(this.imageUri)
            .width('100%')
            .objectFit(ImageFit.Contain)
            .scale({ x: this.scaleValue, y: this.scaleValue })
            .gesture(
              PinchGesture()
                .onActionEnd((event: GestureEvent) => {
                  // 缩放处理
                  const newScale = this.scaleValue * event.scale
                  if (newScale >= 0.5 && newScale <= 3.0) {
                    this.scaleValue = newScale
                  }
                })
            )
        } else {
          Text('无图片')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // ---- 底部提示 ----
      Text('双指缩放 | 点击关闭')
        .fontSize(12)
        .fontColor('#FFFFFFAA')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000EE')
    .onClick(() => {
      // 点击背景关闭
      this.controller.close()
    })
  }
}
