using System;
using System.Linq;
using System.Transactions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace nv.PriorityQueue
{
    [TestClass]
    public class QueueTests
    {
        private static int MaxType = 200;

        // Use ClassInitialize to run code before running the first test in the class
        [ClassInitialize()]
        public static void MyClassInitialize(TestContext testContext)
        {
            using (var c = new ModelDataContext())
            {
                c.Types.DeleteAllOnSubmit(c.Types);
                c.SubmitChanges();

                for (short i = 1; i <= MaxType; i++)
                {
                    Type t = new Type {Id = i, Name = Guid.NewGuid().ToString()};
                    c.Types.InsertOnSubmit(t);
                }

                c.SubmitChanges();
            }

        }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }

        [TestMethod]
        public void Enqueue()
        {
            using (var c = new ModelDataContext())
            {
                var type = (byte)StaticRandom.Next(1, MaxType);
                var tenant = (short) StaticRandom.Next(1, 10000);
                var principal = (short) StaticRandom.Next(1, 10000);
                var priority = (byte) StaticRandom.Next(1, 255);
                c.usp_Enqueue(type, Guid.NewGuid().ToString(), tenant, principal, priority);
            }
        }

        [TestMethod]
        public void Dequeue()
        {
            using (var c = new ModelDataContext())
            {
                using (var s = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions {IsolationLevel = IsolationLevel.ReadCommitted}))
                {
                    c.usp_Dequeue().FirstOrDefault();
                    s.Complete();
                }
            }

        }


    }

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

    interface IPriorityQueue
    {
        Message Dequeue();
        long Enqueue(string payload);
    }

    class PriorityQueue : IPriorityQueue
    {
        long Enqueue(string payload, string tenantId = null, string principalId = null, byte? priority = null)
        {
            
        }
    }
}
