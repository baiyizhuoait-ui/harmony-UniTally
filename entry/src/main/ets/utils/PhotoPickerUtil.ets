/**
 * PhotoPickerUtil - 图片选择工具类
 * 封装 photoAccessHelper，兼容预览器环境
 * 预览器不支持 @ohos.file.photoAccessHelper，需在运行时检测
 */
import photoAccessHelper from '@ohos.file.photoAccessHelper'
import { promptAction } from '@kit.ArkUI'

class PhotoPickerUtil {
  // 是否支持图片选择（预览器环境不支持）
  private isSupported: boolean = true

  /**
   * 选择单张图片
   * @returns 图片 URI，失败返回空字符串
   */
  async pickSingleImage(): Promise<string> {
    if (!this.isSupported) {
      console.warn('[PhotoPickerUtil] 图片选择在当前环境不支持')
      return ''
    }

    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker()
      const photoSelectOptions: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }

      const photoSelectResult = await photoPicker.select(photoSelectOptions)
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        return photoSelectResult.photoUris[0]
      }
      return ''
    } catch (error) {
      // 检测是否是预览器环境不支持导致的错误
      const errMsg = String(error)
      if (errMsg.includes('not support') || errMsg.includes('undefined') || errMsg.includes('null')) {
        this.isSupported = false
        console.warn('[PhotoPickerUtil] 检测到当前环境不支持图片选择API')
        try {
          promptAction.showToast({ message: '预览器不支持图片选择功能' })
        } catch (e) {
          // ignore
        }
        return ''
      }
      console.error('[PhotoPickerUtil] 图片选择失败:', error)
      return ''
    }
  }

  /**
   * 检查当前环境是否支持图片选择
   */
  checkSupported(): boolean {
    return this.isSupported
  }

  /**
   * 重置支持状态（用于重新检测）
   */
  resetSupported(): void {
    this.isSupported = true
  }
}

// 导出单例
export const photoPickerUtil = new PhotoPickerUtil()
