using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace nv.PriorityQueue
{
    [TestClass]
   public class ConsumerTests
    {
        [TestMethod]
        public void Dequeue()
        {
            using (var c = new PriorityQueueModel())
            {
                using (var s = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.ReadCommitted }))
                {
                    c.usp_Dequeue().FirstOrDefault(); // linq2sql gets angry if you don't open the reader
                    //work
                    s.Complete();
                }
            }
        }

        [TestMethod]
        public void DequeueWithTask()
        {
            Action a = () =>
            {
                using (var c = new PriorityQueueModel())
                {
                    using (
                        var s = new TransactionScope(TransactionScopeOption.Required,
                            new TransactionOptions {IsolationLevel = IsolationLevel.ReadCommitted}))
                    {
                        c.usp_Dequeue().FirstOrDefault(); // linq2sql gets angry if you don't open the reader
                        //work
                        s.Complete();
                    }
                }
            };

            Task taskA = new Task(a);
            Task taskB = new Task(a);
            
            var tasks = new List<Task> {taskA, taskB};
            tasks.ForEach(t => t.Start());
            Task.WaitAll(tasks.ToArray());
        }
    }
}
