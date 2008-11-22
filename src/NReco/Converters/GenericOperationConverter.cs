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
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Reflection;

using NReco.Collections;
using NReco.Operations;

namespace NReco.Converters {

	/// <summary>
	/// Provider interfaces converter
	/// </summary>
	public class GenericOperationConverter : BaseGenericTypeConverter {
		
		protected override bool CanConvertFromGeneric { get { return true; } }
		protected override bool CanConvertToGeneric { get { return true; } }
		protected override Type GenDefIType { get { return typeof(IOperation<>); } }
		protected override Type NonGenIType { get { return typeof(IOperation); } }

		public GenericOperationConverter() { }

		protected override object ConvertFromGeneric(object o, Type fromGenIType) {
			Type[] prvGArgs = fromGenIType.GetGenericArguments();
			Type prvType = typeof(OperationWrapper<>).MakeGenericType(prvGArgs);
			return Activator.CreateInstance(prvType, new object[] { o });
		}
		protected override object ConvertToGeneric(object o, Type toGenIType) {
			Type[] prvGArgs = toGenIType.GetGenericArguments();
			Type genPrvType = typeof(GenericOperationWrapper<>).MakeGenericType(prvGArgs);
			return Activator.CreateInstance(genPrvType, new object[] { o });
		}

		protected override bool IsCompatibleGArg(int idx, Type fromType, Type toType) {
			return idx==0 && fromType.IsAssignableFrom(toType);
		}

	}
}
