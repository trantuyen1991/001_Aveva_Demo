								📘 HƯỚNG DẪN SỬ DỤNG WIDGET: Custom Widget: Line Chart (Time Series)  - 🆔 Version V1.0-24072025

 I. 📊 BIỂU ĐỒ ĐƯỢC HỖ TRỢ

        | STT | Loại biểu đồ                   | `chartType` |
        | --- | ------------------------------ | ----------- |
        | 1️⃣ | Biểu đồ đường XY cơ bản (line) | `0`         |

---

 II. 📦 ĐỊNH DẠNG DỮ LIỆU

  🔹 Realtime:

  Gửi từ AVEVA vào `dataChart` dưới dạng JSON:

    Sub Screen_WhileOpen()
      $lineChart01_Server.dataChart = BuildJsonFromTagList($lineChart01_Server.tagList)
    End Sub
  
  * `tagList` sẽ được widget khởi tạo dựa trên `_Cconfig.json`

  🔹 History:
  Tạo từ truy vấn SQL → lưu file JSON → gửi lại widget

  If $lineChart01.sqlQuery Then
    Call CreateChartJsonFromConfig($deviceID, $startDT, $endDT, $numRow, $randomID)
    $lineChart01.sqlQuery = 0
    $lineChart01.sqlQueryDone = 1
  End If

  * Sau khi có dữ liệu:
    * Widget đọc file `randomID_H.json` và lưu vào `hisdataTemp`
    * AVEVA sẽ xóa file này khi có flag:

  If $lineChart01.sqlQueryDone Then
    Call DeleteJsonFile($deviceID, $randomID)
    $lineChart01.sqlQueryDone = 0
  End If

  📌 Các event phụ:

  * `onload`: tạo sẵn thư mục lưu file cấu hình nếu chưa có
  * `onExitFullscreen`: kích hoạt redraw lại biểu đồ

  ---

 III. 🧰 CẤU HÌNH LẦN ĐẦU

1. Gán widget lên AVEVA screen và thiết lập tag
2. Copy toàn bộ code trong file `aveva.vba` vào Main Procedures
3. Save as HTML → Run để khởi tạo widget
4. Trên AVEVA:

   * Set `menuVis = 1` để hiển thị icon menu ⚙
   * Nhấn `Chart Setting` để cấu hình

🔹 Có 2 cách cấu hình:

* **Tạo mới**: điền thông số → `Save` → file `_Cconfig.json` và `_Dconfig.json` được tạo
* **Tải lại từ file có sẵn**: Chọn file → chỉnh sửa → lưu đè

📂 Cấu trúc thư mục:

```
...\Web\Widgets\01_ChartConfig\<deviceID>\
 ├─ _Cconfig.json    # cấu hình riêng widget (UI, tên trục,...)
 └─ _Dconfig.json    # cấu hình kết nối AVEVA (SQL, DB,...)
```

> ⚠️ Không đổi tên file, widget sẽ không đọc được

---

 IV. 🎯 VỊ TRÍ LEGEND (`legendPos`)

🅰️ Đơn ký tự:

| Giá trị | Vị trí        |
| ------- | ------------- |
| `t`     | Top-Center    |
| `b`     | Bottom-Center |
| `l`     | Left-Middle   |
| `r`     | Right-Middle  |

🅱️ Cụ thể:

| Giá trị | Vị trí       |
| ------- | ------------ |
| `t-l`   | Top-Left     |
| `t-r`   | Top-Right    |
| `b-l`   | Bottom-Left  |
| `b-r`   | Bottom-Right |
| `l-t`   | Left-Top     |
| `l-b`   | Left-Bottom  |
| `r-t`   | Right-Top    |
| `r-b`   | Right-Bottom |

🛠 Nếu không đặt, mặc định là `b`

---

 V. 🎨 ĐỔI GIAO DIỆN (`theme`)

| Theme hỗ trợ sẵn                                                                                              |
| ------------------------------------------------------------------------------------------------------------- |
| infographic, dark, vintage, chalk, shine, macarons, roma, essos, purple-passion, walden, westeros, wonderland |

🔁 Có thể đổi theme động bằng `cwidget.theme`

---

 VI. ⚙️ CÁC PROPERTY HỖ TRỢ TRONG AVEVA

| Tên Property       | Chức năng                            |
| ------------------ | ------------------------------------ |
| `deviceID`         | ID của biểu đồ → thư mục cấu hình    |
| `dataChart`        | Dữ liệu JSON                         |
| `chartType`        | Loại biểu đồ                         |
| `titleName`        | Tiêu đề biểu đồ                      |
| `unit`             | Đơn vị (hiện trong tooltip)          |
| `legendPos`        | Vị trí chú thích                     |
| `theme`            | Giao diện                            |
| `refesh`           | Làm mới giao diện                    |
| `readMode`         | Chế độ `1 = history`, `0 = realtime` |
| `sqlQuery`         | Flag yêu cầu truy vấn                |
| `sqlQueryDone`     | Flag hoàn tất truy vấn               |
| `randomID`         | Tên file json tạm thời               |
| `startDT`, `endDT` | Thời gian truy xuất dữ liệu          |
| `numOfRow`         | Số dòng giới hạn khi truy vấn        |

---

 VII. ❗ LƯU Ý & GIỚI HẠN

* Phải đúng định dạng JSON, nếu không biểu đồ sẽ fallback sang dữ liệu mẫu
* Không thay đổi tên file `_Cconfig.json`, `_Dconfig.json`
* Với realtime, tagList cần đủ và trùng với cấu hình đã save
* Lưu ý khi dùng `readMode = 1`, bạn cần truyền đủ `startDT`, `endDT`, `numOfRow`

---

📩 Nếu cần thêm các loại biểu đồ khác (area, spline, stacked line), bạn có thể mở rộng `chartType` và xử lý thêm trong `updateChart()`.



