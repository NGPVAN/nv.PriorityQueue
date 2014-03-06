namespace nv.PriorityQueue
{
    interface IPriorityQueue
    {
        Message Dequeue();
        long Enqueue(string payload, string tenantId = null, string principalId = null, byte? priority = null);

        /*	var x = @"<JobRequest z:Id=""i1"" i:type=""ReportJobRequest"" xmlns=""http://schemas.datacontract.org/2004/07/Ngp.Oberon.Jobs"" xmlns:i=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:z=""http://schemas.microsoft.com/2003/10/Serialization/""><JobId>0</JobId><Name i:nil=""true""/><Params i:nil=""true"" xmlns:a=""http://schemas.microsoft.com/2003/10/Serialization/Arrays""/><RequestingJobId i:nil=""true""/><RunOnSeperateAppDomain>false</RunOnSeperateAppDomain><ExportFormat>Pdf</ExportFormat><QueryInstanceId>25448</QueryInstanceId></JobRequest>";	
	        string type = "Ngp.Oberon.Jobs.ReportJobRequest, Ngp.Oberon.Jobs";
	        Type t = Type.GetType(type);
	        var d = new DataContractSerializer(t);
	        x.Dump();
	        d.ReadObject(new MemoryStream(ASCIIEncoding.ASCII.GetBytes(x))).Dump();	
	        t.Dump();
        */
    }
}