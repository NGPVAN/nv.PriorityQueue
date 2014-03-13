using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace nv.PriorityQueue
{
    [TestClass]
    public class ProducerTests
    {
        [TestMethod]
        public void Enqueue()
        {
            using (var c = new PriorityQueueModel())
            {
                string type = "Type" + StaticRandom.Next(1, 200);
                var tenant = (short) StaticRandom.Next(1, 10000);
                var principal = (short) StaticRandom.Next(1, 10000);
                var priority = (byte) StaticRandom.Next(1, 255);
                string payload = Guid.NewGuid().ToString();
                c.usp_Enqueue(payload, type, tenant, principal, priority);
            }
        }
    }
}
