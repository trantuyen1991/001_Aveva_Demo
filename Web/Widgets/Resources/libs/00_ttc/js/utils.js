// 📁 UTILS.JS - Hỗ trợ widget ECharts Funnel
// -----------------------------------------------
// ✅ Tối ưu: xử lý fullscreen, resize, popup
// ✅ Giữ nguyên comment, debug bổ sung rõ ràng
// ✅ Không delay, không xung đột tài nguyên

// 📦 Biến toàn cục lưu kích thước gốc widget
let originalSize = { width: 0, height: 0 };

// 🧠 Kiểm tra chế độ fullscreen đang bật hay không
function isFullscreen() {
  return document.fullscreenElement ||
         document.webkitFullscreenElement ||
         document.mozFullScreenElement ||
         document.msFullscreenElement;
}

// 🔁 Toggle chế độ fullscreen
function toggleFullscreen() {
  const el = document.getElementById("Container_ID");
  if (!el) return;

  if (!isFullscreen()) {
    if (el.requestFullscreen) el.requestFullscreen();
    else if (el.webkitRequestFullscreen) el.webkitRequestFullscreen();
    else if (el.msRequestFullscreen) el.msRequestFullscreen();
    else if (el.mozRequestFullScreen) el.mozRequestFullScreen();
  } else {
    if (document.exitFullscreen) document.exitFullscreen();
    else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
    else if (document.msExitFullscreen) document.msExitFullscreen();
    else if (document.mozCancelFullScreen) document.mozCancelFullScreen();
  }
}
// 🔁 Refesh chart
function reintChart(){
    changeTheme(cwidget.theme);
    // cwidget.dispatchEvent("onExitFullscreen");
}
// 🔁 Theo dõi sự kiện fullscreen → đổi icon và resize lại
document.addEventListener("fullscreenchange", function () {
  const btn = document.getElementById("enterFullscreenBtn");
  const icon = btn?.querySelector("img");
  if (icon) {
    icon.src = isFullscreen()
      ? "../Resources/Images/compress-solid.svg"
      : "../Resources/Images/expand-solid.svg";
  }
  // ✅ Khôi phục kích thước nếu thoát fullscreen
  const html = document.documentElement;
  const body = document.body;
  const container = document.getElementById("Container_ID");
  if (!isFullscreen() && originalSize.width && originalSize.height) {
    html.style.width = originalSize.width + "px";
    html.style.height = originalSize.height + "px";
    body.style.width = originalSize.width + "px";
    body.style.height = originalSize.height + "px";
    container.style.width = originalSize.width + "px";
    container.style.height = originalSize.height + "px";
    reintChart();
    // console.log("↩️ Khôi phục kích thước từ originalSize:", originalSize);
  }

  if (window.myChart && typeof myChart.resize === "function") {
    myChart.resize();
  }
  updateSizeDisplay();
});

// 📏 Cập nhật kích thước widget hiển thị ở góc phải dưới
function updateSizeDisplay() {
  const container = document.getElementById("Container_ID");
  const box = document.getElementById("originalSizeDisplay");
  if (!container || !box || typeof container.getBoundingClientRect !== "function") {
    // DOM chưa sẵn sàng → bỏ qua lần này
    return;
  }

  const rect = container.getBoundingClientRect();
  const w = Math.round(rect.width);
  const h = Math.round(rect.height);

  box.innerHTML = `W:${w}px&nbsp;H:${h}px`;

  // ✅ Lưu kích thước gốc 1 lần duy nhất nếu chưa fullscreen
  if (!isFullscreen() && originalSize.width === 0 && originalSize.height === 0) {
    originalSize.width = w;
    originalSize.height = h;
    // console.log("✅ originalSize được lưu lần đầu:", originalSize);
  }
}
//
let pendingResize = false;

function safeUpdateSizeDisplay() {
  if (pendingResize) return;
  pendingResize = true;
  requestAnimationFrame(() => {
    updateSizeDisplay();
    pendingResize = false;
  });
}

window.addEventListener("load", updateSizeDisplay);
window.addEventListener("resize", safeUpdateSizeDisplay);

// ⚙️ Đóng/mở popup config
const settingsToggleBtn = document.getElementById("settingsToggle");
if (settingsToggleBtn) {
  settingsToggleBtn.onclick = function () {
    const popup = document.getElementById("settingsPopup");
    popup.style.display = popup.style.display === "block" ? "none" : "block";
    if (popup.style.display === "block") {
      const title = cwidget?.titleName || "";
      const unit = cwidget?.unit || "";
      document.getElementById("chartTitleInput").value = title;
      document.getElementById("unitInput").value = unit;
    }
  };
}

// 🚫 Đóng popup nếu click ra ngoài
document.addEventListener("click", function (event) {
  const popup = document.getElementById("settingsPopup");
  const toggle = document.getElementById("settingsToggle");
  if (!popup.contains(event.target) && !toggle.contains(event.target)) {
    popup.style.display = "none";
  }
});

// 💾 Gửi ngược dữ liệu Title & Unit về AVEVA bindings
const applyBtn = document.getElementById("applySettings");
if (applyBtn) {
  applyBtn.onclick = function () {
    const title = document.getElementById("chartTitleInput").value;
    const unit = document.getElementById("unitInput").value;
    cwidget.titleName = title;
    cwidget.unit = unit;
    // console.log("💾 Đã apply Title & Unit về AVEVA");
  };
}
// Popup Setting 
//  <!-- Khởi tạo Flatpickr -->

    flatpickr("#startDT", {
      enableTime: true,
      time_24hr: true,
      dateFormat: "Y-m-d",
      defaultDate: new Date()
    });
    flatpickr("#endDT", {
      enableTime: true,
      time_24hr: true,
      dateFormat: "Y-m-d",
      defaultDate: new Date()
    });

// <!-- Load + Save + Reset JSON Config -->
  // Update data khi mở cửa sổ config
  const chartSetting = document.getElementById("chartSetting");
  chartSetting.addEventListener("click",() => {
    document.getElementById("titleName").value = cwidget.titleName || "";
    document.getElementById("deviceID").value = cwidget.deviceID || "";//config.deviceID
  })
  // Hàm đọc file JSON và đổ dữ liệu vào form
  function loadConfigFromFile(event) {
    const file = event.target.files[0];
    if (!file) return;
      const reader = new FileReader();
      reader.onload = function (e) {
      try {
        const config = JSON.parse(e.target.result);
        for (const key in config) {
          if (config.hasOwnProperty(key)) {
            const input = document.getElementById(key);
            if (input) {
              input.value = config[key];  // Gán giá trị vào input
            }
          }
        }
        alert("✅ Đã nạp file cấu hình thành công!");
      } catch (err) {
        alert("❌ Lỗi khi đọc file JSON: " + err.message);
      }
    };
    reader.readAsText(file);
    // Option 2 
    // const files = e.target.files;

    // for (let i = 0; i < files.length; i++) {
    //   const file = files[i];
    //   const reader = new FileReader();

    //   reader.onload = function (event) {
    //     const jsonData = JSON.parse(event.target.result);
    //     console.log(`📂 File ${file.name}:`, jsonData);

    //     // Gán vào input nếu id trùng key
    //     for (const key in jsonData) {
    //       if (jsonData.hasOwnProperty(key)) {
    //         const el = document.getElementById(key);
    //         if (el) el.value = jsonData[key];
    //       }
    //     }
    //   };

    //   reader.readAsText(file);
    // }

  }
  // Hàm Download file to PC
  function downloadJsonFile(fileName, jsonObject) {
    const jsonStr = JSON.stringify(jsonObject);
    const blob = new Blob([jsonStr], { type: "application/json" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = fileName;
    a.click();

    URL.revokeObjectURL(url); // Giải phóng bộ nhớ
  }

  // Hàm lưu cấu hình ra file JSON
  function saveConfig() {
    // Kiểm tra bắt buộc: ít nhất 3 trường quan trọng
    const requiredFields = ["titleName", "deviceID", "sqlDNS"];
    for (let id of requiredFields) {
      const val = document.getElementById(id).value.trim();
      if (!val) {
        alert("❌ Trường \"" + id + "\" không được để trống!");
        document.getElementById(id).focus();
        return;
      }
    }

    const dataConfig = {
      // title: document.getElementById("titleName").value.trim(),
      deviceID: document.getElementById("deviceID").value.trim(),
      sqlDNS: document.getElementById("sqlDNS").value.trim(),
      dbName: document.getElementById("dbName").value.trim(),
      dbTable: document.getElementById("dbTable").value.trim(),
      dbColumn: document.getElementById("dbColumn").value.split(",").map(s => s.trim()).filter(Boolean),
      dataName: document.getElementById("dataName").value.split(",").map(s => s.trim()).filter(Boolean),
      type: document.getElementById("type").value.split(",").map(s => s.trim()).filter(Boolean),
      // xAxisName: document.getElementById("xAxisName").value.trim(),
      // xAxisUnit: document.getElementById("xAxisUnit").value.trim(),
      // yAxisName: {
      //   name: document.getElementById("yAxisName").value.trim(),
      //   unit: document.getElementById("yAxisUnit").value.trim()
      // },
      // startDT: document.getElementById("startDT").value,
      // endDT: document.getElementById("endDT").value
    };
    const chartConfig = {
      title: document.getElementById("titleName").value.trim(),
      // deviceID: document.getElementById("deviceID").value.trim(),
      // sqlDNS: document.getElementById("sqlDNS").value.trim(),
      // dbName: document.getElementById("dbName").value.trim(),
      // dbTable: document.getElementById("dbTable").value.trim(),
      // dbColumn: document.getElementById("dbColumn").value.split(",").map(s => s.trim()).filter(Boolean),
      dataName: document.getElementById("dataName").value.split(",").map(s => s.trim()).filter(Boolean),
      type: document.getElementById("type").value.split(",").map(s => s.trim()).filter(Boolean),
      xAxisName: document.getElementById("xAxisName").value.trim(),
      xAxisUnit: document.getElementById("xAxisUnit").value.trim(),
      yAxisName: document.getElementById("yAxisName").value.trim(),
      yAxisUnit: document.getElementById("yAxisUnit").value.trim()
      // startDT: document.getElementById("startDT").value,
      // endDT: document.getElementById("endDT").value
    };
    
    // 🔽 Tạo file tải xuống PC:
    const dataFileName = dataConfig.deviceID + "_Dconfig.json";
    const chartFileName = dataConfig.deviceID + "_Cconfig.json";

    downloadJsonFile(dataFileName, dataConfig);
    downloadJsonFile(chartFileName, chartConfig);
  
    // Cap nhat len chart
    cwidget.deviceID = document.getElementById("deviceID").value.trim();
    cwidget.titleName = document.getElementById("titleName").value.trim();
    cwidget.tagList = document.getElementById("dbColumn").value.trim().split(",").slice(1).join(",");
    LoadChartConfig();
    // initChart();
  }

  // Hàm reset toàn bộ form
  function resetForm() {
    const fields = document.querySelectorAll("#configForm input");
    fields.forEach(el => el.value = "");
  }
// Hàm Chuyển đổi Realtime / Historycal
const sqlReques = document.getElementById('applyDate');
const startDT1 = document.getElementById('startDT1');
const endDT1 = document.getElementById('endDT1');

const datePickerContainer = document.getElementById('datePickerContainer');
const inputNumOfRow = document.getElementById("inputNumOfRow")
const ClassinputNumOfRow = document.getElementById("ClassinputNumOfRow")
const toggleBtn = document.getElementById('modeToggle');
toggleBtn.addEventListener('click', () => {
  const icon = toggleBtn.querySelector('i');
  const isRealtime = icon.classList.contains('bi-lightning');
  
  if (isRealtime) {
    cwidget.readMode = true;
    readMode = 1;
    // detecReadMode();
    // console.log("Hiện Gửi readMode:", 1);
  } else {
    readMode = 0;
    cwidget.readMode = false;
    // detecReadMode();
    // console.log("Ẩn Gửi readMode:", 0);
  }
});

function detecReadMode(){
  const icon = toggleBtn.querySelector('i');
  const today = new Date();
  const dayFormatted = today.toISOString().slice(0, 10);  // ➜ "2025-07-19"
  if (readMode == 1){
    // console.log("Hiện Data Picker:");
    toggleBtn.title = "Realtime";
    startDT1.value =  cwidget.startDT || dayFormatted;//
    endDT1.value =  cwidget.endDT || dayFormatted;//
    ClassinputNumOfRow.classList.add('d-none');
    datePickerContainer.classList.remove('d-none'); // hiện
    icon.className = 'bi bi-clock-history';
    toggleBtn.innerHTML = '<i class="bi bi-clock-history"></i>';
  } else if (readMode == 0) {
    // console.log("Ẩn Data Picker:");
  // cwidget.sqlQuery = false;
    toggleBtn.title = "History";
    datePickerContainer.classList.add('d-none');     // ẩn
    ClassinputNumOfRow.classList.remove('d-none');
    icon.className = 'bi bi-lightning';
    toggleBtn.innerHTML = '<i class="bi bi-lightning"></i>';
  }
}
  //
window.addEventListener("load", function () {
  const icon = toggleBtn.querySelector('i');
  const datePickerContainer = document.getElementById('datePickerContainer');
  const isRealtime = icon.classList.contains('bi-clock-history');

  // if (isRealtime) {
  //   ClassinputNumOfRow.classList.add('d-none');
  //   datePickerContainer.classList.remove('d-none'); // hiện
  // } else {
  //   datePickerContainer.classList.add('d-none');     // ẩn
  //   ClassinputNumOfRow.classList.remove('d-none');
  // }
});

// Gửi requet truy xuất DATA BASE cho AVEVA 
sqlReques.addEventListener('click', () => {
  cwidget.startDT = startDT1.value;
  cwidget.endDT = endDT1.value;
  cwidget.sqlQuery = true;
  cwidget.sqlQueryDone = false;
  cwidget.dispatchEvent("sqlQueryHistory");
});
//Cập nhận số dòng request realtime
inputNumOfRow.addEventListener("change", function () {
  const value = parseInt(this.value);
  if (!isNaN(value)) {
    cwidget.numOfRow = value;
    // console.log("Gửi numOfRow: ",value);
  }
});
