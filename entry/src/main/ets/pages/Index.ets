/**
 * 应用入口页面
 * 路由指向 MainIndex 主界面
 */
import { MainIndex } from './MainIndex'

@Preview
@Entry
@Component
struct Index {
  build() {
    Column() {
      MainIndex()
    }
    .width('100%')
    .height('100%')
  }
}