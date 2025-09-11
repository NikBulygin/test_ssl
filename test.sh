# Проверка доступности SOAP сервиса Directum
curl -v https://directum-server/IntegrationServices.svc


curl -v -X POST \
  -u "username:password" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"http://tempuri.org/IIntegrationServices/GetReferenceChangedFrom\"" \
  -d '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetReferenceChangedFrom xmlns="http://tempuri.org/">
      <referenceName>КДГ</referenceName>
      <fromDate>2024-01-01</fromDate>
      <toDate></toDate>
    </GetReferenceChangedFrom>
  </soap:Body>
</soap:Envelope>' \
  https://directum-server/IntegrationServices.svc

  curl -v -X POST \
  --ntlm \
  -u "domain\\username:password" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"http://tempuri.org/IIntegrationServices/GetReferenceChangedFrom\"" \
  -d '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetReferenceChangedFrom xmlns="http://tempuri.org/">
      <referenceName>КДГ</referenceName>
      <fromDate>2024-01-01</fromDate>
      <toDate></toDate>
    </GetReferenceChangedFrom>
  </soap:Body>
</soap:Envelope>' \
  https://directum-server/IntegrationServices.svc

  curl -v -X POST \
  --ntlm \
  -u "domain\\username:password" \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"http://tempuri.org/IIntegrationServices/RunScript\"" \
  -d '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <RunScript xmlns="http://tempuri.org/">
      <scriptName>GetEmployeeID</scriptName>
      <parameters>
        <string>Login</string>
        <string>bulygin_n</string>
      </parameters>
    </RunScript>
  </soap:Body>
</soap:Envelope>' \
  https://directum-server/IntegrationServices.svc

  curl -v --trace-ascii directum_trace.txt \
  --ntlm \
  -u "domain\\username:password" \
  -X POST \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"http://tempuri.org/IIntegrationServices/GetReferenceChangedFrom\"" \
  -d '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetReferenceChangedFrom xmlns="http://tempuri.org/">
      <referenceName>КДГ</referenceName>
      <fromDate>2024-01-01</fromDate>
      <toDate></toDate>
    </GetReferenceChangedFrom>
  </soap:Body>
</soap:Envelope>' \
  https://directum-server/IntegrationServices.svc

  curl -v -k --ntlm \
  -u "domain\\username:password" \
  -X POST \
  -H "Content-Type: text/xml; charset=utf-8" \
  -H "SOAPAction: \"http://tempuri.org/IIntegrationServices/GetReferenceChangedFrom\"" \
  -d '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetReferenceChangedFrom xmlns="http://tempuri.org/">
      <referenceName>КДГ</referenceName>
      <fromDate>2024-01-01</fromDate>
      <toDate></toDate>
    </GetReferenceChangedFrom>
  </soap:Body>
</soap:Envelope>' \
  https://directum-server/IntegrationServices.svc

  curl -v --ntlm \
  -u "domain\\username:password" \
  https://directum-server/IntegrationServices.svc?wsdl