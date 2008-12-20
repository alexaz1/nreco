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
using System.Collections;
using System.Text;

using NReco;
using NReco.Collections;
using ognl;

namespace NReco.OGNL {
	
	/// <summary>
	/// OGNL expression evaluator
	/// </summary>
	public class OgnlExprProvider : OgnlEval, IProvider<ExpressionContext<string>,object> {
		public object Provide(ExpressionContext<string> context) {
			return Eval(context.Expression, context.Variables);
		}

	}
}
