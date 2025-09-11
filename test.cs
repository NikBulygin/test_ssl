using Directum.Integration;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using Serilog;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.ServiceModel;
using System.ServiceModel.Channels;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;
using UKTMK.Salesportal.Core.DataContracts.Directum;
using UKTMK.Salesportal.Core.Interfaces;
using UKTMK.Salesportal.Database;
using UKTMK.Salesportal.Database.Models;
using Record = UKTMK.Salesportal.Core.DataContracts.Directum.Record;
using Task = System.Threading.Tasks.Task;

namespace UKTMK.Salesportal.Core.Services
{
    public class DirectumManager : IDirectumManager
    {
        private readonly TenderDocumentGenerator _documentGenerator;
        private readonly SalesPortalContext _context;

        private static readonly Dictionary<string, string> FormsOfBusinessMapping;
        private static IConfiguration _configuration;

        static DirectumManager()
        {
            var basePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            var filePath = Path.Combine(basePath, "FormsOfBusinessMapping.json");
            var json = File.ReadAllText(filePath);
            FormsOfBusinessMapping = JsonConvert.DeserializeObject<Dictionary<string, string>>(json);
        }

        public DirectumManager(TenderDocumentGenerator documentGenerator, SalesPortalContext context, IConfiguration configuration)
        {
            _context = context;
            _documentGenerator = documentGenerator;
            _configuration = configuration;
        }

        private async Task<T> CallApi<T>(Func<IntegrationServices, Task<T>> callbackFunc)
        {
            try
            {
                var credential = Convert.ToBase64String(Encoding.ASCII.GetBytes(_configuration.GetSection("Directum:Login").Value + ":" + _configuration.GetSection("Directum:Password").Value));

                var url = _configuration.GetSection("Directum:Url").Value;

                var securityMode = new System.ServiceModel.BasicHttpBinding(BasicHttpSecurityMode.None);

                securityMode.MaxReceivedMessageSize = 2147483647;
                securityMode.Security.Transport.ClientCredentialType = HttpClientCredentialType.None;

                Task<T> task;
                var client = new IntegrationServicesClient() { Endpoint = { Address = new EndpointAddress(url), Binding = securityMode} };

                using (OperationContextScope scope = new OperationContextScope(client.InnerChannel))
                {
                    OperationContext.Current.OutgoingMessageProperties[HttpRequestMessageProperty.Name] =
                        new HttpRequestMessageProperty()
                        {
                            Headers =
                            {
                                {"Authorization", $"Basic {credential}"},
                            }
                        };
                    task = callbackFunc(client);
                }

                return await task;
            }
            catch (Exception e)
            {
                Log.Warning(e, $"Directum error, IntegrationServices DirectumManager + {e.Message}");
                return default;
            }
        }

        private T DeserializeObject<T>(string xml)
        {
            // Create an instance of the XmlSerializer.
            XmlSerializer serializer = new XmlSerializer(typeof(T));

            // Declare an object variable of the type to be deserialized.
            T i;

            using Stream reader = new MemoryStream(Encoding.UTF8.GetBytes(xml));
            i = (T)serializer.Deserialize(reader);

            return i;
        }

        public async Task<List<KeyValuePair<string, string>>> GetContractCategories()
        {
            var directumContactTypeDate = _configuration.GetSection("Directum:ContactTypeDate").Value;
            var xmlResult = await CallApi(services => services.GetReferenceChangedFromAsync("КДГ", directumContactTypeDate, null));
            var package = DeserializeObject<DataExchangePackage>(xmlResult).Object.Record.Select(SelectNameAndId).ToList();
            return package;
        }

        private KeyValuePair<string, string> SelectNameAndId(Record arg)
        {
            var section = arg.Section.First(x => x.Index == "0");
            var name = section.Requisite.FirstOrDefault(x => x.Name == "Наименование").Text;
            var id = section.Requisite.FirstOrDefault(x => x.Name == "ИД").Text;
            return new KeyValuePair<string, string>(id, name);
        }

        public async Task<string> GetEmployeeID(string login)
        {
            var param = new Dictionary<string, string>
            {
                {"Login",login}
            };
            return await CallApi(services => services.RunScriptAsync("GetEmployeeID", param));
        }

        private string FormatXmlRequest(string templatename, Dictionary<string, string> param)
        {
            var basePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            var template = File.ReadAllText(Path.Combine(basePath, $"Resources\\DataExchangePackages\\{templatename}.xml"));
            foreach (var pair in param)
            {
                template = template.Replace($"{{{pair.Key}}}", pair.Value);
            }

            return template;
        }

        public async Task<string> CreateContract(string contactTypeId, string name, string employeeId, string orgId, byte[] file)
        {
            var param = new Dictionary<string, string>
            {
                {"ContactTypeId", contactTypeId},
                {"ContactName", name},
                {"EmployeeId", employeeId},
                {"OrgId", orgId},
            };
            var request = FormatXmlRequest("CreateContract", param);
            Log.Information("Calling Directum EDocumentsCreateAsync: {request}", request);
            var resp = await CallApi(services => services.EDocumentsCreateAsync(request, new[] { file }, null));
            Log.Information("Calling Directum EDocumentsCreateAsync result:{result}", resp);
            return resp?.FirstOrDefault()?.Split(';')?.LastOrDefault();
        }

        public async Task<string> CreateOtherAsync(FileUpload file)
        {
            var editor = GetEditor(file.Name);
            var param = new Dictionary<string, string>
            {
                {"editor", (editor ?? "ACROREAD")},
                {"name", file.Name},
            };
            var request = FormatXmlRequest("CreateOther", param);
            Log.Information("Calling Directum CreateOtherAsync: {request}", request);
            var resp = await CallApi(services => services.EDocumentsCreateAsync(request, new[] { file.Content }, null));
            Log.Information("Calling Directum CreateOtherAsync result:{result}", resp);
            return resp?.FirstOrDefault()?.Split(';')?.LastOrDefault();
        }

        public async Task<string> CreateNotifyUserAsync(string login, string subject, string text)
        {
            var param = new Dictionary<string, string>
            {
                {"Login", login},
                {"Subject", subject},
                {"Text", text},
            };

            Log.Information("Calling Directum CreateNotifyUserAsync: {request}", param);
            var result = await CallApi(services => services.RunScriptAsync("NotifyUser", param));
            Log.Information("Calling Directum CreateNotifyUserAsync result:{result}", result);
            return result;
        }

        private string GetEditor(string fileName)
        {
            var editor = Path.GetExtension(fileName) switch
            {
                ".pdf" => "ACROREAD",
                ".doc" => "WORD",
                ".docx" => "WORD",
                ".xls" => "EXCEL2007",
                ".xlsx" => "EXCEL2007",
                _ => null,
            };
            Log.Information("Got editor:{editor} for file:{file}", editor, fileName);
            return editor;
        }

        public async Task<string> SearchOrg(string orgName)
        {
            Log.Information("Calling Directum SearchOrg: {orgName}", orgName);
            var param = new Dictionary<string, string>
            {
                {"OrgName",GetOrgName(orgName)}
            };
            var result = await CallApi(services => services.RunScriptAsync("SearchOrg", param));
            Log.Information("Calling Directum SearchOrg: {orgName} result:{result}", orgName, result);
            return result == "0" ? null : result;
        }

        public async Task<string> CreateOrg(Supplier supplier)
        {
            var param = new Dictionary<string, string>
            {
                {"id", "0"},
                {"name", GetOrgName(supplier.SupplierName)},
                {"inn", supplier.Bin},
                {"address", supplier.LegalAddress.FormatDirectum()},
                {"factAddress", supplier.ActualAddress.FormatDirectum(supplier.LegalAddress)},
                {"countryId", await GetCountryId(supplier.LegalAddress.Country) ?? "146529"},
                {"email", supplier.OrganizationData.Email},
                {"bik", ""},
                {"bank", ""},
                {"iik", ""},
                {"director", supplier.ChiefName},

            };
            var request = FormatXmlRequest("CreateOrg", param);
            var result = await CallApi(services => services.ReferencesUpdateWithScriptAsync(request, "PP", false));
            var id = result?.FirstOrDefault()?.Split(';')?.LastOrDefault();
            id = string.IsNullOrWhiteSpace(id) || id == "0" ? null : id;

            return id;
        }

        private async Task<string> GetCountryId(string country)
        {
            var param = new Dictionary<string, string>
            {
                {"Country",country}
            };
            var result = await CallApi(services => services.RunScriptAsync("SearchCountry", param));
            return result == "0" ? null : result;
        }

        public async Task<string> CreateTenderTaskAsync(Tender tender, TenderParticipant winner, List<FileUpload> attachedDocuments)
        {
            var directumAttachedDocuments = await GenerateDirectumDocsAsync(tender, winner, attachedDocuments);

            var requestDoc = new List<string> { directumAttachedDocuments.CJId };
            requestDoc.AddRange(directumAttachedDocuments.AttachedDocuments.Where(x=> !string.IsNullOrEmpty(x)));

            var task = await CreateTask(directumAttachedDocuments.ContactId, requestDoc);

            if (!string.IsNullOrEmpty(task))
            {
                tender.DirectumAttachedDocuments = directumAttachedDocuments;
            }

            return task;
        }

        public async Task<DirectumAttachedDocuments> UpdatedTenderTaskAsync(Tender tender, TenderParticipant winner,
            List<FileUpload> attachedDocuments)
        {
            var newTenderDoc = new DirectumAttachedDocuments();

            var docs = await GenerateDirectumDocsAsync(tender, winner, attachedDocuments);
            var dbDocs = tender.DirectumAttachedDocuments.AttachedDocuments.ToList();

            docs.AttachedDocuments.Insert(0, dbDocs.First());

            if (tender.DirectumAttachedDocuments != null)
            {
                await MergeDocAsync(tender.DirectumAttachedDocuments.ContactId, docs.ContactId);
                newTenderDoc.ContactId = docs.ContactId;

                await MergeDocAsync(tender.DirectumAttachedDocuments.CJId, docs.CJId);
                newTenderDoc.CJId = docs.CJId;

                for (int i = 0; i < tender.DirectumAttachedDocuments.AttachedDocuments.Count; i++)
                {
                    if (i < tender.DirectumAttachedDocuments.AttachedDocuments.Count() && i < docs.AttachedDocuments.Count())
                        await MergeDocAsync(dbDocs[i], docs.AttachedDocuments[i]);
                }
            }
            newTenderDoc.AttachedDocuments.AddRange(docs.AttachedDocuments);

            return newTenderDoc;
        }

        public async Task<DirectumAttachedDocuments> GenerateDirectumDocsAsync(Tender tender, TenderParticipant winner, List<FileUpload> attachedDocuments)
        {
            var orgId = await SearchOrg(winner.Supplier?.SupplierName);
            if (orgId == null)
            {
                orgId = await CreateOrg(winner.Supplier);
            }

            orgId ??= "";

            var employeeId = tender?.Creator?.DirectumEmployeeID ?? "";

            //var contactTypeId = tender?.TenderType?.DirectumContractTypeId ?? "1730712";
            var tenderContractTemplate = await _context.TenderContractTemplates.FirstOrDefaultAsync(x => x.Id == (int)tender.ContractTemplateTypeId);
            var contactTypeId = tenderContractTemplate?.DirectumContractTypeId ?? tender?.TenderType?.DirectumContractTypeId; //?? "1730712";

            var competitiveJustification = await _documentGenerator.GenerateCompetitiveJustificationAsync(tender);
            var contract = await _documentGenerator.GenerateContactAsync(winner, tender);
            var contactId = await CreateContract(contactTypeId, tender?.Name, employeeId, orgId, contract);
            //var memoId = await CreateServiceMemo(tender.Name, employeeId, competitiveJustification);
            attachedDocuments.ForEach(x =>
                x.Name = x.Name.Replace("main.pdf", $"Результат тендера #{tender.Id} - {tender.Name}.pdf")
            );

            var docs = await CreateOtherAsync(new FileUpload
            {
                Name = $"Конкурентное обоснование #{tender.Id}.xlsx",
                Content = competitiveJustification,
                Type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            });

            var ids = new List<string>();
            foreach (var document in attachedDocuments)
            {
                ids.Add(await CreateOtherAsync(document));
            }

            return new DirectumAttachedDocuments()
            {
                ContactId = contactId,
                CJId = docs,
                AttachedDocuments = ids,
            };
        }

        public async Task FinalTaskAsync(string directumTaskId, string reason)
        {
            var param = new Dictionary<string, string>
            {
                {"TaskID",GetOrgName(directumTaskId)},
                {"Reason",reason??"Поставщик согласован!"},
            };
            var result = await CallApi(services => services.RunScriptAsync("FinalTask", param));
            Log.Information("FinalTask returned:{result} ", result);
        }

        public static string GetOrgName(string supplierName)
        {
            foreach (var form in FormsOfBusinessMapping)
            {
                supplierName = supplierName.Replace(form.Key, form.Value, true, CultureInfo.CurrentCulture);
            }

            supplierName = supplierName.Trim();
            bool sameStr;
            do
            {
                var newName = supplierName.Replace("  ", " ");
                sameStr = newName.Length == supplierName.Length;
                supplierName = newName;
            } while (!sameStr);

            return supplierName;
        }

        public async Task<string> CreateServiceMemo(string topic, string employeeId, byte[] file)
        {
            var param = new Dictionary<string, string>
            {
                {"Topic", topic},
                {"EmployeeId", employeeId},
            };
            var request = FormatXmlRequest("ServiceMemo", param);
            Log.Information("Calling Directum EDocumentsCreateAsync: {request}", request);
            var resp = await CallApi(services => services.EDocumentsCreateAsync(request, new[] { file }, null));
            Log.Information("Calling Directum EDocumentsCreateAsync result:{result}", resp);
            return resp?.FirstOrDefault()?.Split(';')?.LastOrDefault();
        }

        public async Task<string> MergeDocAsync(string first, string second)
        {
            var param = new Dictionary<string, string>
            {
                {"First", first},
                {"Second", second},
            };

            Log.Information("Calling Directum MergeDocs: {request}", param);
            var result = await CallApi(services => services.RunScriptAsync("MergeDocs", param));
            Log.Information("Calling Directum MergeDocs result:{result}", result);
            return result;
        }

        public async Task<string> CreateTask(string contractId, List<string> otherDocs)
        {
            var otherDocStr = string.Concat(otherDocs.Select(x => $"<Attachment ID=\"{x}\" Type=\"EDocument\"/>"));
            var param = new Dictionary<string, string>
            {
                {"ContractId", contractId},
                //{"MemoId", memoId},
                {"OtherDocuments", otherDocStr},
            };
            var request = FormatXmlRequest("CreateTask", param);
            Log.Information("Calling Directum CreateTaskAsync: {request} docs:{otherDocs}", request, otherDocs);
            var resp = await CallApi(services => services.CreateTaskAsync(request, null));
            Log.Information("Calling Directum CreateTaskAsync result:{result}", resp);
            return resp;
        }
    }
}


// 2025-09-11 05:32:02.989 +00:00 [WRN] Directum error, IntegrationServices DirectumManager + NTLM authentication is not possible with default credentials on this platform.
System.PlatformNotSupportedException: NTLM authentication is not possible with default credentials on this platform.
   at System.Runtime.AsyncResult.End[TAsyncResult](IAsyncResult result)
   at System.ServiceModel.Channels.ServiceChannel.SendAsyncResult.End(SendAsyncResult result)
   at System.ServiceModel.Channels.ServiceChannel.EndCall(String action, Object[] outs, IAsyncResult result)
   at System.ServiceModel.Channels.ServiceChannelProxy.TaskCreator.<>c__DisplayClass1_0.<CreateGenericTask>b__0(IAsyncResult asyncResult)
--- End of stack trace from previous location ---
   at UKTMK.Salesportal.Core.Services.DirectumManager.CallApi[T](Func`2 callbackFunc) in /src/UKTMK.Salesportal.Core/Services/DirectumManager.cs:line 83