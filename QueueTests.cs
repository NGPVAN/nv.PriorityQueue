using System;
using System.Linq;
using System.Transactions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace nv.PriorityQueue
{
    [TestClass]
    public class QueueTests
    {
        [TestMethod]
        public void Enqueue()
        {
            using (var c = new QueueContext())
            {
                var type = (byte)StaticRandom.Next(1, 200);
                var tenant = (short) StaticRandom.Next(1, 10000);
                var principal = (short) StaticRandom.Next(1, 10000);
                var priority = (byte) StaticRandom.Next(1, 255);
                c.Enqueue(type, Guid.NewGuid().ToString(), tenant, principal, priority);
            }
        }

        [TestMethod]
        public void Dequeue()
        {
            using (var c = new QueueContext())
            {
                using (var s = new TransactionScope(TransactionScopeOption.RequiresNew,
                        new TransactionOptions {IsolationLevel = IsolationLevel.ReadCommitted}))
                {                    
                    c.Dequeue();                    
                    s.Complete();
                }
            }

        }
    }
}
