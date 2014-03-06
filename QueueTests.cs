using System;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Collections.Generic;
using System.Threading;
using System.Transactions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace nv.PriorityQueue
{
    interface IPriorityQueue {
        public IEnumerable<object o> Dequeue();
        public long Enqueue(object o);    
    }

    [TestClass]
    public class QueueTests
    {
        [TestMethod]
        public void Enqueue()
        {
            using (var c = new QueueContext())
            {
                c.Enqueue((byte)StaticRandom.Next(1, 128), (short)StaticRandom.Next(1, 8), Guid.NewGuid().ToString());
            }
        }

        [TestMethod]
        public void Dequeue()
        {
            using (var c = new QueueContext())
            {
                using (var s = new TransactionScope(TransactionScopeOption.RequiresNew,
                        new TransactionOptions() {IsolationLevel = IsolationLevel.ReadCommitted}))
                {                    
                    var workBatch = c.Dequeue();

                    foreach (var w in workBatch)
                    {
                        // do work
                        if (w != null)
                        {
                            c.AcknowledgeCompletion(w.Id);
                        }
                    }

                    s.Complete();
                }
            }

        }
    }
}
