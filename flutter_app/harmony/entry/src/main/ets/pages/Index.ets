@Entry
@Component
struct Index {
  @State message: string = 'ScanPDF';
  @State isLoading: boolean = true;

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          Text(this.message)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1976D2')
          
          Text('智能扫描办公')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 10 })
          
          LoadingProgress()
            .width(60)
            .height(60)
            .margin({ top: 40 })
            .color('#1976D2')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
