#region License
/*
 * NReco library (http://code.google.com/p/nreco/)
 * Copyright 2008 Vitaliy Fedorchenko
 * Distributed under the LGPL licence
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#endregion

using System;
using System.Collections.Generic;
using System.Text;

namespace NReco.Operations {
	
	/// <summary>
	/// Dynamic version of InvokeMethod. All properties of InvokeMethod could be dependent from context.
	/// </summary>
	public class DynamicInvokeMethod : IOperation, IProvider {

		InvokeMethod InvokeMethodInstance = null;
		IProvider _TargetProvider = null;
		IProvider<object,string> _MethodNameProvider = null;
		IProvider[] _ArgumentProviders = null;

		public IProvider TargetProvider {
			get { return _TargetProvider; }
			set { _TargetProvider = value; }
		}

		public IProvider<object,string> MethodNameProvider {
			get { return _MethodNameProvider; }
			set { _MethodNameProvider = value; }
		}

		public IProvider[] ArgumentProviders {
			get { return _ArgumentProviders; }
			set { _ArgumentProviders = value; }
		}

		public DynamicInvokeMethod() { }

		public DynamicInvokeMethod(InvokeMethod invokeMethodInstance) {
			InvokeMethodInstance = invokeMethodInstance;
		}

		public void Execute(object context) {
			Provide(context);
		}

		public object Provide(object context) {
			InvokeMethod invoke = InvokeMethodInstance==null ? new InvokeMethod() : InvokeMethodInstance;
			if (TargetProvider!=null)
				invoke.TargetObject = TargetProvider.Provide(context);
			if (MethodNameProvider!=null)
				invoke.MethodName = MethodNameProvider.Provide(context);
			if (ArgumentProviders!=null) {
				object[] args = new object[ArgumentProviders.Length];
				for (int i=0; i<ArgumentProviders.Length; i++)
					args[i] = ArgumentProviders[i].Provide(context);
				invoke.Arguments = args;
			}
			return invoke.Provide(context);
		}

	}

}