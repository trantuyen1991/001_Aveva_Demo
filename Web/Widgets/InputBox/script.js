const labels = document.querySelectorAll('.form-control label')

labels.forEach(label => {
    label.innerHTML = label.innerText
        .split('')
        .map((letter, idx) => `<span style="transition-delay:${idx * 50}ms">${letter}</span>`)
        .join('')
})

const inputNum = document.getElementById("inputNum")
const btApply = document.getElementById("btApply")
btApply.addEventListener("click", function(){
    if (cwidget.TagName != inputNum.value){
        // cwidget.TagName = inputNum.value;
        console.log("✅ Widget TagName Change:", inputNum.value);
    } else {
        console.log("✅ Widget TagName Update:", inputNum.value);
    }
  
});

// 📡 Binding dữ liệu từ AVEVA
cwidget.on("TagName", function () {
    if (inputNum.value != cwidget.TagName) {
        inputNum.value = cwidget.TagName;
        console.log("✅ Aveva TagName Change:", cwidget.TagName);
    } else{
        console.log("✅ Aveva TagName Update:", cwidget.TagName);
    }
    
});