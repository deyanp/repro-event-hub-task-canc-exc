namespace Company.Function

open System
open System.Collections.Concurrent
open Microsoft.Azure.WebJobs
open Microsoft.Azure.WebJobs.Extensions.Http
open Microsoft.AspNetCore.Http
open Microsoft.Extensions.Logging
open Microsoft.AspNetCore.Mvc
open Microsoft.Azure.EventHubs

//module AzureEventHubs =
//    
//    let lookup : ConcurrentDictionary<string, EventHubClient> = ConcurrentDictionary()
//
//    let getClientSingleton connectionString initialize : EventHubClient =
//        lookup.GetOrAdd(connectionString + initialize.GetType().GetHashCode().ToString(),
//                        (fun _ -> initialize connectionString))
//
//    let getClient (connectionString:string) :EventHubClient =
//        let initialize (connectionString:string) :EventHubClient =
//            EventHubClient.CreateFromConnectionString(connectionString)    
//        getClientSingleton connectionString initialize

module HttpTrigger =
    
    [<Literal>]
    let eventHubConnectionStringKey = "EventHubsConnectionString"
    let eventHubConnectionString = Environment.GetEnvironmentVariable(eventHubConnectionStringKey, EnvironmentVariableTarget.Process)
//    let eventHubClient = lazy(AzureEventHubs.getClient eventHubConnectionString) 
    let eventHubClient = lazy(EventHubClient.CreateFromConnectionString(eventHubConnectionString)) 
  
    let consumerGroup = "$Default"
    
    [<FunctionName("CheckEventHubs")>]
    let checkEventHubs ([<HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)>]req: HttpRequest) (log: ILogger) =
        eventHubClient.Force().GetRuntimeInformationAsync()
//        async {
//            log.LogInformation("CheckEventHubs function started")
//
//            do! eventHubClient.Force().GetRuntimeInformationAsync() |> Async.AwaitTask |> Async.Ignore
//            
//            log.LogInformation("CheckEventHubs function finished successfully")
//            return OkObjectResult("CheckEventHubs function finished successfully") :> IActionResult
//        } |> Async.StartAsTask
