using System;

namespace nv.PriorityQueue
{
    class Message
    {
        long Id { get; set; }
        short TenantId { get; set; }
        short PrincipalId { get; set; }
        string Type { get; set; }
        byte Priority { get; set; }
        bool? IsInProgress { get; set; }
        string Payload { get; set; }
        DateTime CreatedOn { get; set; }
        DateTime ModifiedOn { get; set; }
    }
}