# Nicepayment Cordova

- [Nicepay 연동 메뉴얼](https://developers.nicepay.co.kr/index.php)
- [Nicepay Git](https://github.com/nicepayments/nicepay-manual)

<hr>

## 호출

```javascript
var params = {
    data: {
        // 기본적인 Nicepay 결제 호출 시 필요한 Data 작성
        Endpoint: Array // 해당 위치에 도달하면 결제를 종료합니다.
    },
    options: {
        withNavigation: Boolean, // Navigation Bar 표출 여부 boolean 값 입니다.
        withBackButton: Boolean, // Navigation Bar 에 Back Button 포함 여부 boolean 값 입니다.
        withCloseButton: Boolean, // Navigation Bar 에 Close Button 포함 여부 boolean 값 입니다.
        title: String, // Navigation Bar Title String 값 입니다.
        buttonColor: String, // Navigation Bar Button 색상 코드 또는 앱 System Color 명 String 값 입니다.
        titleColor: String, // Navigation Bar Title 색상 코드 또는 앱 System Color 명 String 값 입니다.
        backgroundColor: String, // Navigation Bar 배경 색상 코드 또는 앱 System Color 명 String 값 입니다.
        withHeader: Object // 인증 처리 후 도달한 Redirect URL에 함께 전송할 추가적인 Request Header Key-Value Object 값 입니다. 
    },
    onSuccess: Function,
    onFail: Function
};

cordova.plugins.NicepayCordova.payment(params);
```

<br><br>

### 개발 편의성 제공

- window.Nicepay 내부 Constant 값 존재.
- data.NpLang 이 `"@SYSTEM"` 또는 `Nicepay.SYSTEM` 일 때 앱 언어 설정 값으로 설정됨.
- data.CurrencyCode 이 `"@SYSTEM"` 또는 `Nicepay.SYSTEM` 일 때 앱 국가 설정 값으로 설정됨.
- data.IspCancelUrl, data.WapUrl 이 `"@SYSTEM"` 또는 `Nicepay.SYSTEM` 일 때 앱 Scheme 또는 Package Name 으로 설정됨.
- data.PayMethod 를 `Array<String>` 으로 작성 가능.
  ```
  - 예시) [Nicepay.PayMethod.Card, Nicepay.PayMethod.Phone]
  → "CARD,CELLPHONE"
  ```
- data.QuotaInterest 를 `Object` 으로 작성 가능.
  ```
  - 예시) {"01": [6, 7], "02": [3, 4]}
  → "01:06,07|02:03,04"
  ```
- options.title 이 `"@SYSTEM"` 또는 `Nicepay.SYSTEM` 일 때 앱 이름 값으로 설정됨.
- options.buttonColor, options.titleColor, options.backgroundColor 을 아래와 같이 작성 가능.
  ```
  - 예시) Nicepay.Color(255, 255, 255)
  → "#ffffff"
  ```
- options.withHeader 을 작성하여 추가적인 Request Header 데이터 전송 가능.

<br><br>

### 호출 예시

```javascript
var params = {
    data: {
        PayMethod: [Nicepay.PayMethod.Card, Nicepay.PayMethod.CellPhone],
        CharSet: "utf-8",
        NpLang: Nicepay.NpLang.SYSTEM,
        Moid: "ORDER28109245120123",
        MID: "nicepay00m",
        GoodsName: "상품명",
        EdiDate: "20230518170632",
        CurrencyCode: Nicepay.CurrencyCode.KoreanWon,
        SignData: "SIGN DATA",
        Amt: 1000,
        BuyerName: "구매자",
        WapUrl: Nicepay.SYSTEM,
        IspCancelUrl: Nicepay.SYSTEM,
        ReturnURL: "http://192.168.0.91:8080/api/test/",
        Endpoint: ["http://192.168.0.91:8080/api/test/"],
        QuotaInterest: {
            "01": [6, 7],
            "02": [3, 4]
        },
        SkinType: Nicepay.SkinType.Red
    },
    options: {
        withNavigation: true,
        withBackButton: true,
        withCloseButton: true,
        title: Nicepay.SYSTEM,
        buttonColor: Nicepay.Color(0, 0, 0),
        titleColor: Nicepay.Color(0, 0, 0),
        backgroundColor: Nicepay.Color(255, 255, 255),
        withHeader: {
            authorization: "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJHVUVTVDE2ODQ3Mjc2NjQzOTQiLCJhdXRoIjoiSE9NRU1CRVIiLCJleHAiOjEwMzI0NzI3NjY0fQ.erKfDD0EtCQaD16QnRknDCNkTNSrtd5tI9eGdN63WqJs5FtLYqcqwCh0HO9D0Sc0bmIsQ3f3KIGnfybT19zblA"
        }
    },
    onSuccess: (message) => {
        alert("SUCCESS!!")
        alert(message)
    },
    onFail: (message) => {
        alert("FAIL")
        alert(message)
    }
};
```
`1,000` `원(KRW)`의 `상품명`을 `구매자`가 결제 하는 `빨간색 스킨` 타입을 가진 `카드 결제`, `휴대폰 결제`가 가능한 결제 창에 `사용자 기기의 언어 설정`을 따라 표출 되며, 
`흰색 바탕`에 `검은색` 뒤로 가기 버튼과 `검은색` 닫기 버튼, `앱 이름의 타이틀` 이 존재 하는 네비게이션 바가 표출 됩니다.
인증 이후 `Authorization 정보를 함께` 전송합니다.

<hr>

## 응답

### 성공

1. 지정된 `Endpoint`에 도달 했을 경우.

```javascript
response = {
   "status": "success",
   "resultCode": "100",
   "message": "결제 성공"
}
```

### 실패

1. `https://web.nicepay.co.kr/v3/smart/common/error.jsp` 에 도달 했을 경우.

```javascript
response = {
    "status": "fail",
    "resultCode": "0204",
    //error.jsp QueryParameter의 errCd,
    "message": "세션이 끊어졌거나 오류가 발생하였습니다. 가맹점 페이지로 가서 다시 결제하여 주십시요." 
    //error.jsp QueryParameter의 errMsg
}
```

2. 사용자가 결제 화면에서 이탈 했을 경우.

```javascript
response = {
    "status": "fail",
    "resultCode": "-100",
    "message": "사용자 취소"
}
```

3. 결제 데이터 파싱에 실패 했을 경우.

```javascript
response = {
    "status": "fail",
    "resultCode": "-101",
    "message": "결제 정보 오류"
}
```

<hr>
