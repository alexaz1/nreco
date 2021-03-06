#region License
/*
 * NReco library (http://nreco.googlecode.com/)
 * Copyright 2008-2014 Vitaliy Fedorchenko
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
using System.IO;
using System.Web;
using System.Web.UI;
using System.Web.Routing;
using System.Text;
using System.Linq;
using System.Drawing;
using System.Drawing.Imaging;

using NReco;
using NReco.Application.Web;
using NReco.Logging;
using NReco.Dsm.Vfs;
using NI.Vfs;
using NI.Ioc;

namespace NReco.Dsm.WebForms.Vfs { 

	public class UploadHandler : IHttpHandler {
	
		static ILog log = LogManager.GetLogger(typeof(UploadHandler));
	
		protected string InvalidFileTypeMessage = "Invalid file type";
	
		public bool IsReusable {
			get { return true; }
		}
	
		public virtual void ProcessRequest(HttpContext context) {
			try {
				ProcessRequestInternal(context);
			} catch (Exception ex) {
				log.Write(LogEvent.Error,ex);
			
				var errMsg = AppContext.GetLabel( ex.Message );
				context.Response.Write(errMsg);
				
				context.Response.StatusCode = 500;
				context.Response.StatusDescription = errMsg;
			}
		}

		protected virtual IFileObject GetUniqueFile(IFileSystem fs, string fileName) {
			int fileNum = 0;
			IFileObject uniqueFile = null;
			do {
				fileNum++;
				var extIdx = fileName.LastIndexOf('.');
				var newFileName = extIdx>=0 ? String.Format("{0}{1}{2}", fileName.Substring(0,extIdx), fileNum, fileName.Substring(extIdx) ) : fileName+fileNum.ToString();
				uniqueFile = fs.ResolveFile(newFileName);
			} while ( uniqueFile.Exists() && fileNum<100 );
			if (uniqueFile.Exists()) {
				var extIdx = fileName.LastIndexOf('.');
				var uniqueSuffix = Guid.NewGuid().ToString();
				uniqueFile = fs.ResolveFile(
					extIdx>=0 ?  fileName.Substring(0,extIdx)+uniqueSuffix+fileName.Substring(extIdx) : fileName+uniqueSuffix );
			}
			return uniqueFile;
		}
	
		protected virtual void ProcessRequestInternal(HttpContext context) {
		
			log.Write( LogEvent.Debug, "File upload request: {0}", context.Request.Url.ToString() );
		
			string filesystemName = context.Request["filesystem"];
			if (String.IsNullOrEmpty(filesystemName))
				throw new Exception("Parameter missed: filesystem");
			var fs = AppContext.ComponentFactory.GetComponent<IFileSystem>(filesystemName);
			if (fs==null)
				throw new Exception(String.Format("Component does not exist: {0}", filesystemName));

			string folder = context.Request["folder"] ?? String.Empty;

			var overwrite = false;
			if (context.Request["overwrite"]!=null)
				Boolean.TryParse(context.Request["overwrite"], out overwrite);

			var fileUtils = new HttpFileUtils();
			var result = new List<IFileObject>();

			for (int i=0; i<context.Request.Files.Count; i++) {
				var file = context.Request.Files[i];
				if (String.IsNullOrEmpty(file.FileName.Trim())) { continue; }
				
				var blockedExtensions = AppContext.ComponentFactory.GetComponent<IList<string>>("blockedUploadFileExtensions");
				if (blockedExtensions!=null && blockedExtensions.Contains( Path.GetExtension(file.FileName).ToLower())) {
					throw new Exception(AppContext.GetLabel(InvalidFileTypeMessage));
				}

				var fileInput = new HttpFileUtils.InputFileInfo(file.FileName, file.InputStream) {
					Folder = folder,
					Overwrite = overwrite
				};
				if (context.Request["imageformat"]!=null)
					fileInput.ForceImageFormat = context.Request["imageformat"];
				if (context.Request["image_max_width"]!=null)
					fileInput.ImageMaxWidth = Convert.ToInt32(context.Request["image_max_width"]);
				if (context.Request["image_max_height"] != null) {
					fileInput.ImageMaxHeight = Convert.ToInt32(context.Request["image_max_height"]);
				}

				var uploadFile = fileUtils.SaveFile(fs, fileInput);
				result.Add(uploadFile);
			}
		
			context.Response.Write( JsUtils.ToJsonString( 
				result.Select(f=>
					new Dictionary<string,object> {
						{"name", Path.GetFileName( f.Name ) },
						{"filepath", f.Name },
						{"size", f.Content.Size}
					}
				).ToArray() ) );


		}

	}


}