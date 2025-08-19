'....... Version 1.1 22072025- Chạy oke. fix lỗi không giới hạn số dòng trả về dẫn đến quá tải.
Function CreateChartJsonFromConfig(deviceID,startDT,endDT,numRow,randomID)
    ' --- [0] Khai báo ---
    Dim jsonStr , config, conn, rs, sql
    Dim dbCols, dataNames, dataTypes
    Dim timeList, dataList(), rowJSON, finalJSON
    Dim tableName, fileName, dbName, connStr
    Dim i
    Dim startDT1, endDT1
    Dim intervalSec, stepSec
    'MsgBox deviceID & "-" & startDT & "-" & endDT &  "-" & readMode & "-" & numRow
     ' --- [1] Load File Config ---
	 If deviceID <> "" Then
		jsonStr = LoadFileText($projectPath & "Web\Widgets\01_ChartConfig\" & deviceID & "\" & "_Dconfig.json")
	Else
		MsgBox "deviceID: " & deviceID & "-" &  "startDT : " & startDT & "-" &   "endDT : " & endDT 
	End If
    ' --- [2] Parse JSON cấu hình ---
    Set config = EvalJson(jsonStr ) ' (Hàm EvalJson đã hoạt động OK)

    ' --- [3] Lấy các thông tin cấu hình ---
    connStr    = config("sqlDNS")
    dbName     = config("dbName")
    tableName  = config("dbTable")
    dbCols     = config("dbColumn")      ' Phần tử đầu là Time_Stamp
    dataNames  = config("dataName")      ' Tên dòng dữ liệu (trùng số lượng cột - 1)
    dataTypes  = config("type")          ' Loại biểu đồ: line, bar,...
    
    fileName   =  randomID & "_H.json"

    ' --- [4] Kiểm tra dữ liệu cấu hình đầu vào ---
	If Not IsArray(dbCols) Or Not IsArray(dataNames) Or Not IsArray(dataTypes) Then
        MsgBox "[DEBUG] ❌ Một trong các trường dbColumn, dataName, type không phải array!"
        Exit Function
    End If
    
    If (UBound(dbCols) <> UBound(dataNames) + 1)  Then
        MsgBox "[DEBUG] ❌ Số lượng cột không khớp: dbCols = " & UBound(dbCols) & ", dataNames = " & UBound(dataNames)
        Exit Function
    End If
    ' --- [5] Tính toán step interval nếu vượt quá numRow ---
    	startDT = Replace(startDT, "T", " ")
		endDT   = Replace(endDT, "T", " ")
    intervalSec = DateDiff("s", startDT, endDT)
    If (numRow > 1000) And  (numRow < 2000) Then
        stepSec = intervalSec \ numRow
        If stepSec < 1 Then stepSec = 1
    ElseIf (numRow < 1000)  Or (numRow > 2000) Then
        stepSec = intervalSec \ 1000
        If stepSec < 1 Then stepSec = 1    
    ElseIf (numRow > 2000) Then
        stepSec = intervalSec \ 1000
        If stepSec < 1 Then stepSec = 1	
    Else
        stepSec = 1
    End If

    'MsgBox "⏳ Khoảng thời gian truy vấn: " & intervalSec & " giây" & vbCrLf & _
       ' "🎯 Số dòng tối đa yêu cầu: " & numRow & vbCrLf & _
       ' "📌 stepSec được tính: " & stepSec

    ' --- [5.1] Kết nối & truy vấn SQL ---
    sql = "SELECT " & Join(dbCols, ",") & " FROM " & tableName & _
        " WHERE " & dbCols(0) & " BETWEEN '" & startDT & "' AND '" & endDT & "'" & _
        " AND MOD(UNIX_TIMESTAMP(" & dbCols(0) & "), " & stepSec & ") = 0" & _
        " ORDER BY " & dbCols(0) & " ASC"
	 'MsgBox sql 
    Set conn = CreateObject("ADODB.Connection")
    conn.Open connStr
    Set rs = conn.Execute(sql)

    If rs.EOF Then
        MsgBox "[DEBUG] ❌ Không có dữ liệu trong khoảng thời gian truy vấn."
        conn.Close
        Exit Function
    End If

    ' --- [6] Khởi tạo danh sách ---
    ReDim dataList(UBound(dbCols) - 1)
    For i = 0 To UBound(dataList)
        dataList(i) = ""
    Next
    timeList = ""

    ' --- [7] Duyệt dữ liệu từ SQL ---
    Do While Not rs.EOF
        timeList = timeList & """" & FormatToISO(rs(dbCols(0))) & ""","

        For i = 1 To UBound(dbCols)
            'dataList(i - 1) = dataList(i - 1) & rs(dbCols(i)) & ","
            dataList(i - 1) = dataList(i - 1) & Replace(CStr(Round(rs(dbCols(i)), 2)), ",", ".") & ","
        Next

        rs.MoveNext
    Loop

    ' --- [8] Cắt dấu , cuối ---
    If Len(timeList) > 0 Then timeList = "[" & Left(timeList, Len(timeList) - 1) & "]"

    For i = 0 To UBound(dataList)
        If Len(dataList(i)) > 0 Then
            dataList(i) = "[" & Left(dataList(i), Len(dataList(i)) - 1) & "]"
        Else
            dataList(i) = "[]"
        End If
    Next

    ' --- [9] Tạo JSON hoàn chỉnh ---
    finalJSON = "{"
    'finalJSON = finalJSON & """title"": """ & config("title") & ""","
    finalJSON = finalJSON & """timeStamp"": " & timeList & ","
    finalJSON = finalJSON & """legend"": " & JoinStringArray(dataNames) & ","
    'finalJSON = finalJSON & """seriesType"": " & JoinStringArray(dataTypes) & ","
    'finalJSON = finalJSON & """xAxisName"": """ & config("xAxisName") & ""","
    'finalJSON = finalJSON & """yAxisName"": {""name"": """ & config("yAxisName")("name") & """, ""unit"": """ & config("yAxisName")("unit") & """},"
    finalJSON = finalJSON & """data"": [" & Join(dataList, ",") & "]"
    finalJSON = finalJSON & "}"

    ' --- [10] Ghi file ---
    SaveTextToFileWithFolderCheck $projectPath & "Web\Widgets\\02_ChartData\\" & config("deviceID"), $projectPath & "Web\Widgets\\02_ChartData\\" & config("deviceID") & "\\" & fileName, finalJSON

    'MsgBox "[DEBUG] ✅ Đã tạo file JSON: " & fileName

    conn.Close
End Function
'===========================================
' ✅ HÀM PHỤ 
'===========================================
  ' --- [11] Các Hàm phụ trợ ---
Function FormatToISO(dt)
    FormatToISO = Year(dt) & "-" & Right("0" & Month(dt), 2) & "-" & Right("0" & Day(dt), 2) & _
                  " " & Right("0" & Hour(dt), 2) & ":" & Right("0" & Minute(dt), 2) & ":" & Right("0" & Second(dt), 2)
End Function

Function JoinStringArray(arr)
    Dim i, result
    result = "["
    For i = 0 To UBound(arr)
        result = result & """" & arr(i) & """"
        If i < UBound(arr) Then result = result & ","
    Next
    result = result & "]"
    JoinStringArray = result
End Function
'===========================================
' ✅ DELETE FILE SAU KHI ĐÃ ĐỌC XONG
'===========================================
Sub DeleteJsonFile(deviceID, randomID )
    Dim fso
    Dim fullPath
    fullPath= $projectPath & "Web\Widgets\02_ChartData\" & deviceID & "\" & randomID & "_H.json"
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' --- Kiểm tra nếu file tồn tại ---
    If fso.FileExists(fullPath) Then
        On Error Resume Next
        fso.DeleteFile fullPath, True  ' True: xóa luôn nếu đang readonly
        If Err.Number = 0 Then
            'MsgBox "🗑 File đã được xóa thành công: " & fullPath
        Else
            'MsgBox "❌ Lỗi khi xóa file: " & Err.Description
        End If
        On Error GoTo 0
    Else
        'MsgBox "⚠ File không tồn tại: " & fullPath
    End If

    Set fso = Nothing
End Sub
'===========================================
' ✅ LƯU FILE CÓ KIỂM TRA FOLDER
'===========================================
Sub SaveTextToFileWithFolderCheck(parentFolder, filePath, content)
    Dim fso, folderParent, folderPath, f
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
        ' --- Lấy đường dẫn thư mục từ đường dẫn file ---
    folderParent= fso.GetParentFolderName(parentFolder)

    ' --- Kiểm tra và tạo thư mục nếu chưa tồn tại ---
    If Not fso.FolderExists(folderParent) Then
        fso.CreateFolder folderParent
    End If


    ' --- Lấy đường dẫn thư mục từ đường dẫn file ---
    folderPath = fso.GetParentFolderName(filePath)

    ' --- Kiểm tra và tạo thư mục nếu chưa tồn tại ---
    If Not fso.FolderExists(folderPath) Then
        fso.CreateFolder folderPath
    End If
	
    ' --- Ghi nội dung vào file ---
	If Trim(content) <> "" Then
	    Set f = fso.CreateTextFile(filePath, True) ' True = overwrite
	    f.Write content
	    f.Close
	    'MsgBox "✅ Đã tạo file thành công: " & filePath
	Else
	    'MsgBox "⚠ Nội dung rỗng, không ghi file: " & filePath
	End If		
End Sub

'===========================================
' ✅ HÀM PHỤ LOAD FILE JSON
'===========================================

Function LoadFileText(path)
    Dim fso, f, text
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set f = fso.OpenTextFile(path, 1)
    text = f.ReadAll
    f.Close
    Set f = Nothing
    Set fso = Nothing
    LoadFileText = text
End Function

'===========================================
' ✅ HÀM CHÍNH GỌI PARSE JSON
'===========================================
Function EvalJson(jsonStr)
    Dim cleaned, dict

    ' Làm sạch chuỗi JSON (bỏ dòng trắng, tab, khoảng trắng thừa)
    cleaned = Replace(jsonStr, vbCrLf, "")
    cleaned = Replace(cleaned, vbTab, "")
    cleaned = Replace(cleaned, " ", "")

    If Left(cleaned, 1) = "{" Then
        Set dict = ParseJsonObject(cleaned)
        Set EvalJson = dict
    Else
        Set EvalJson = Nothing
    End If
End Function


'===========================================
' ✅ PARSE OBJECT { ... }
'===========================================
Function ParseJsonObject(text)
    Dim obj, i, key, val, token, tokens

    Set obj = CreateObject("Scripting.Dictionary")
    text = Mid(text, 2, Len(text) - 2) ' loại bỏ dấu {}

    tokens = SplitJsonTokens(text)

    For i = 0 To UBound(tokens)
        token = tokens(i)
        If InStr(token, ":") > 0 Then
            key = Trim(Mid(token, 1, InStr(token, ":") - 1))
            val = Trim(Mid(token, InStr(token, ":") + 1))
            key = Replace(key, """", "")

            ' Kiểm tra value
            If Left(val, 1) = "[" Then
                obj.Add key, ParseJsonArray(val)
            ElseIf Left(val, 1) = "{" Then
                obj.Add key, ParseJsonObject(val)
            Else
                If Left(val, 1) = """" Then
                    val = Replace(val, """", "")
                    obj.Add key, val
                ElseIf IsNumeric(val) Then
                    obj.Add key, CDbl(val)
                Else
                    obj.Add key, val
                End If
            End If
        End If
    Next

    Set ParseJsonObject = obj
End Function


'===========================================
' ✅ PARSE ARRAY [ ... ]
'===========================================
Function ParseJsonArray(text)
    Dim items, i, val, arr()

    text = Mid(text, 2, Len(text) - 2) ' loại bỏ dấu []
    items = SplitJsonArrayItems(text)
    ReDim arr(UBound(items))

    For i = 0 To UBound(items)
        val = Trim(items(i))
        If Left(val, 1) = """" Then
            arr(i) = Replace(val, """", "")
        ElseIf Left(val, 1) = "[" Then
            arr(i) = ParseJsonArray(val)
        ElseIf Left(val, 1) = "{" Then
            Set arr(i) = ParseJsonObject(val)
        ElseIf IsNumeric(val) Then
            arr(i) = CDbl(val)
        Else
            arr(i) = val
        End If
    Next

    ParseJsonArray = arr
End Function


'===========================================
' ✅ TÁCH TOKEN trong JSON object
'===========================================
Function SplitJsonTokens(json)
    Dim result(), i, inStr, inObj, inArr, chr, buf, c
    ReDim result(0)
    buf = ""
    inStr = False: inObj = 0: inArr = 0: c = 0

    For i = 1 To Len(json)
        chr = Mid(json, i, 1)

        If chr = """" Then inStr = Not inStr
        If Not inStr Then
            If chr = "{" Then inObj = inObj + 1
            If chr = "}" Then inObj = inObj - 1
            If chr = "[" Then inArr = inArr + 1
            If chr = "]" Then inArr = inArr - 1
        End If

        If chr = "," And Not inStr And inObj = 0 And inArr = 0 Then
            ReDim Preserve result(c)
            result(c) = buf
            buf = ""
            c = c + 1
        Else
            buf = buf & chr
        End If
    Next

    ReDim Preserve result(c)
    result(c) = buf
    SplitJsonTokens = result
End Function


'===========================================
' ✅ TÁCH MẢNG JSON ARRAY
'===========================================
Function SplitJsonArrayItems(arrStr)
    Dim result(), i, chr, buf, inStr, inObj, inArr, c
    ReDim result(0)
    buf = ""
    inStr = False: inObj = 0: inArr = 0: c = 0

    For i = 1 To Len(arrStr)
        chr = Mid(arrStr, i, 1)

        If chr = """" Then inStr = Not inStr
        If Not inStr Then
            If chr = "{" Then inObj = inObj + 1
            If chr = "}" Then inObj = inObj - 1
            If chr = "[" Then inArr = inArr + 1
            If chr = "]" Then inArr = inArr - 1
        End If

        If chr = "," And Not inStr And inObj = 0 And inArr = 0 Then
            ReDim Preserve result(c)
            result(c) = buf
            buf = ""
            c = c + 1
        Else
            buf = buf & chr
        End If
    Next

    ReDim Preserve result(c)
    result(c) = buf
    SplitJsonArrayItems = result
End Function
'===========================================
' ✅ TẠO CHUỖI JSON TỪ DANH SÁCH TAGLIST THEO THỜI GIAN 
'===========================================
Function BuildJsonFromTagList(tagListStr) 'outputTagName
	Dim tagNames, tagName, tagValue, jsonData, fullJson
	Dim  i
	' Kiểm tra đầu vào
    If Len(tagListStr) = 0 Then
        MsgBox "❌ Danh sách tag rỗng!"
        Exit Function 
    End If

	tagNames = Split(tagListStr, ",")

  	' Duyệt từng tên tag và lấy giá trị
    For i = 0 To UBound(tagNames)
        tagName = Trim(tagNames(i))
        'MsgBox  tagName 
        ' Kiểm tra tag hợp lệ và nối giá trị
        If Len(tagName) > 0 Then
            tagValue = $GetTagValue(tagName)  ' <-- Lấy giá trị tag dựa trên tên
            'MsgBox  tagValue 
            If IsNumeric(tagValue) Then
                jsonData = jsonData & tagValue
            Else
                jsonData = jsonData & "null"
            End If

            If i < UBound(tagNames) Then
                jsonData = jsonData & "," ' Thêm dấu phẩy nếu chưa phải phần tử cuối
            End If
        End If
    Next
    ' Ghép JSON hoàn chỉnh
    fullJson = "{" & """data"":[" & jsonData & "]" & "}"
    'fullJson = fullJson & """legend"": [" & legendList  & "]}"    
    ' Gán kết quả vào tag output
    BuildJsonFromTagList = fullJson
	'MsgBox   fullJson
End Function 