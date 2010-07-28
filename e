diff --git a/src/CommonAssemblyInfo.cs b/src/CommonAssemblyInfo.cs
diff --git a/src/MVCContrib.UnitTests/Filters/PassParametersDuringRedirectAttributeTester.cs b/src/MVCContrib.UnitTests/Filters/PassParametersDuringRedirectAttributeTester.cs
index 619ecac..2f22715 100644
--- a/src/MVCContrib.UnitTests/Filters/PassParametersDuringRedirectAttributeTester.cs
+++ b/src/MVCContrib.UnitTests/Filters/PassParametersDuringRedirectAttributeTester.cs
@@ -1,4 +1,5 @@
 using System.Collections.Generic;
+using System.Web;
 using System.Web.Mvc;
 using MvcContrib.ActionResults;
 using MvcContrib.Filters;
@@ -7,116 +8,105 @@ using Rhino.Mocks;
 
 namespace MvcContrib.UnitTests.Filters
 {
-	[TestFixture]
-	public class PassParametersDuringRedirectAttributeTester
-	{
-		private PassParametersDuringRedirectAttribute _filter;
-		private SomeObject _someObject;
-
-		[SetUp]
-		public void Setup()
-		{
-			_filter = new PassParametersDuringRedirectAttribute();
-			_someObject = new SomeObject {One = 1, Two = "two"};
-		}
-
-		[Test]
-		public void OnActionExecuting_should_load_the_parameter_values_out_of_TempData_when_they_match_both_name_and_type_of_a_parameter_of_the_action_being_executed()
-		{
-		    
-		    var context = new ActionExecutingContext()
-			{
-				Controller = new SampleController(),
-				ActionParameters = new Dictionary<string, object>(),
-                ActionDescriptor = GetActionDescriptorStubForIndexAction()
-			};
-
-			context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
-			context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
-
-			_filter.OnActionExecuting(context);
-
-            context.ActionParameters["viewModel"].ShouldEqual(_someObject);
-            context.ActionParameters["id"].ShouldEqual(5);
-		}
+    [TestFixture]
+    public class PassParametersDuringRedirectAttributeTester
+    {
+        private PassParametersDuringRedirectAttribute _filter;
+        private SomeObject _someObject;
+        private ActionExecutingContext _fakeActionExecutingContext;
+
+        [SetUp]
+        public void Setup()
+        {
+            _filter = new PassParametersDuringRedirectAttribute();
+            _someObject = new SomeObject { One = 1, Two = "two" };
+
+            _fakeActionExecutingContext = new ActionExecutingContext()
+                {
+                    Controller = new SampleController(),
+                    ActionParameters = new Dictionary<string, object>(),
+                    ActionDescriptor = GetActionDescriptorStubForIndexAction()
+                };
+
+            var stubContext = MockRepository.GenerateStub<HttpContextBase>();
+            var stubRequest = MockRepository.GenerateStub<HttpRequestBase>();
+            stubRequest.RequestType = "GET";
+
+            stubContext.Stub(s => s.Request).Return(stubRequest);
+            _fakeActionExecutingContext.HttpContext = stubContext;
+        }
+
+        [Test]
+        public void OnActionExecuting_should_only_load_parameters_from_temp_data_if_the_current_HTTP_request_is_GET()
+        {
+            _fakeActionExecutingContext.HttpContext.Request.RequestType = "POST";
+
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
+
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
+
+            _fakeActionExecutingContext.ActionParameters.Count.ShouldEqual(0);
+        }
+
+        [Test]
+        public void OnActionExecuting_should_load_the_parameter_values_out_of_TempData_when_they_match_both_name_and_type_of_a_parameter_of_the_action_being_executed()
+        {
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
+
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
+
+            _fakeActionExecutingContext.ActionParameters["viewModel"].ShouldEqual(_someObject);
+            _fakeActionExecutingContext.ActionParameters["id"].ShouldEqual(5);
+        }
 
         [Test]
         public void OnActionExecuting_should_load_the_parameter_values_out_of_TempData_when_they_match_the_name_and_are_assignable_to_the_type_of_a_parameter_of_the_action_being_executed()
         {
             var objectAssignableToSomeObject = new ObjectAssignableToSomeObject();
 
-            var context = new ActionExecutingContext()
-            {
-                Controller = new SampleController(),
-                ActionParameters = new Dictionary<string, object>(),
-                ActionDescriptor = GetActionDescriptorStubForIndexAction()
-            };
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = objectAssignableToSomeObject;
 
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = objectAssignableToSomeObject;
-            
-            _filter.OnActionExecuting(context);
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
+
+            _fakeActionExecutingContext.ActionParameters["viewModel"].ShouldEqual(objectAssignableToSomeObject);
 
-            context.ActionParameters["viewModel"].ShouldEqual(objectAssignableToSomeObject);
-            
         }
 
-	    [Test]
+        [Test]
         public void OnActionExecuting_should_not_load_the_parameter_values_out_of_TempData_which_do_not_have_matching_name_and_assignable_type_of_a_parameter_of_the_action_being_executed()
         {
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "theNameOfThisParameterDoesNotMatch"] = _someObject;
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = "the type of this parameter does not match";
 
-            var context = new ActionExecutingContext()
-            {
-                Controller = new SampleController(),
-                ActionParameters = new Dictionary<string, object>(),
-                ActionDescriptor = GetActionDescriptorStubForIndexAction()
-            };
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
+
+            _fakeActionExecutingContext.ActionParameters.ContainsKey("theNameOfThisParameterDoesNotMatch").ShouldBeFalse();
+            _fakeActionExecutingContext.ActionParameters.ContainsKey("param2").ShouldBeFalse();
+        }
 
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "theNameOfThisParameterDoesNotMatch"] = _someObject;
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = "the type of this parameter does not match";
+        [Test]
+        public void OnActionExecuting_should_not_load_null_parameter_values()
+        {
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = null;
 
-            _filter.OnActionExecuting(context);
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
 
-            context.ActionParameters.ContainsKey("theNameOfThisParameterDoesNotMatch").ShouldBeFalse();
-            context.ActionParameters.ContainsKey("param2").ShouldBeFalse();
+            _fakeActionExecutingContext.ActionParameters.ContainsKey("viewModel").ShouldBeFalse();
         }
 
-         [Test]
-        public void OnActionExecuting_should_not_load_null_parameter_values()
-         {
-             var context = new ActionExecutingContext()
-             {
-                 Controller = new SampleController(),
-                 ActionParameters = new Dictionary<string, object>(),
-                 ActionDescriptor = GetActionDescriptorStubForIndexAction()
-             };
-
-             context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = null;
-             
-             _filter.OnActionExecuting(context);
-
-             context.ActionParameters.ContainsKey("viewModel").ShouldBeFalse();
-         }
-        
 
         [Test]
         public void Matching_stored_parameters_values_should_be_kept_in_TempData()
         {
-            
-            var context = new ActionExecutingContext
-            {
-                Controller = new SampleController(),
-                ActionParameters = new Dictionary<string, object>(),
-                ActionDescriptor = GetActionDescriptorStubForIndexAction()
-            };
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
 
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
+            _fakeActionExecutingContext.Controller.TempData.Save(_fakeActionExecutingContext, MockRepository.GenerateStub<ITempDataProvider>());
 
-            _filter.OnActionExecuting(context);
-            context.Controller.TempData.Save(context, MockRepository.GenerateStub<ITempDataProvider>());
-
-            context.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel").ShouldBeTrue();
-            context.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id").ShouldBeTrue();
+            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel").ShouldBeTrue();
+            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id").ShouldBeTrue();
 
         }
 
@@ -126,89 +116,86 @@ namespace MvcContrib.UnitTests.Filters
             var actionDescriptorWithNoParameters = MockRepository.GenerateStub<ActionDescriptor>();
             actionDescriptorWithNoParameters.Stub(ad => ad.GetParameters()).Return(new ParameterDescriptor[] { });
 
-            var context = new ActionExecutingContext
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
+            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
+
+            _filter.OnActionExecuting(_fakeActionExecutingContext);
+            _fakeActionExecutingContext.Controller.TempData.Save(_fakeActionExecutingContext, MockRepository.GenerateStub<ITempDataProvider>());
+
+            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel").ShouldBeFalse();
+            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id").ShouldBeFalse();
+        }
+
+        [Test]
+        public void OnActionExecuted_should_store_parameters_in_tempdata_when_result_is_generic_RedirectToRouteResult()
+        {
+            var context = new ActionExecutedContext()
             {
-                Controller = new SampleController(),
-                ActionParameters = new Dictionary<string, object>(),
-                ActionDescriptor = actionDescriptorWithNoParameters
+                Result = new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5)),
+                Controller = new SampleController()
             };
 
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
-            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;
+            _fakeActionExecutingContext.Result =
+                new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5));
 
-            _filter.OnActionExecuting(context);
-            context.Controller.TempData.Save(context, MockRepository.GenerateStub<ITempDataProvider>());
+            _filter.OnActionExecuted(context);
+            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"].ShouldEqual(_someObject);
+            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"].ShouldEqual(5);
+        }
 
-            context.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel").ShouldBeFalse();
-            context.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id").ShouldBeFalse();
+        [Test]
+        public void Should_not_remove_null_parameters_from_the_route_values()
+        {
+            var context = new ActionExecutedContext
+            {
+                Result = new RedirectToRouteResult<SampleController>(x => x.Index(null, 5)),
+                Controller = new SampleController()
+            };
+
+            _filter.OnActionExecuted(context);
+
+            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"].ShouldBeNull();
         }
 
-		[Test]
-		public void OnActionExecuted_should_store_parameters_in_tempdata_when_result_is_generic_RedirectToRouteResult()
-		{
-			var context = new ActionExecutedContext()
-			{
-				Result = new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5)),
-				Controller = new SampleController()
-			};
-
-			_filter.OnActionExecuted(context);
-			context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"].ShouldEqual(_someObject);
-			context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"].ShouldEqual(5);
-		}
-
-		[Test]
-		public void Should_not_remove_null_parameters_from_the_route_values() 
-		{
-			var context = new ActionExecutedContext
-			{
-				Result = new RedirectToRouteResult<SampleController>(x => x.Index(null, 5)),
-				Controller = new SampleController()
-			};
-
-			_filter.OnActionExecuted(context);
-
-			context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"].ShouldBeNull();
-		}
-
-		[Test]
-		public void Should_remove_items_from_routevalues_once_stored_in_tempdata()
-		{
-			var result = new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5));
-			var context = new ActionExecutedContext() {
-				Result = result,
-				Controller = new SampleController()
-			};
-
-			_filter.OnActionExecuted(context);
-			result.RouteValues.ContainsKey("viewModel").ShouldBeFalse();
-		}
-
-		public class SomeObject
-		{
-			public int One { get; set; }
-			public string Two { get; set; }
-		}
+        [Test]
+        public void Should_remove_items_from_routevalues_once_stored_in_tempdata()
+        {
+            var result = new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5));
+            var context = new ActionExecutedContext()
+            {
+                Result = result,
+                Controller = new SampleController()
+            };
+
+            _filter.OnActionExecuted(context);
+            result.RouteValues.ContainsKey("viewModel").ShouldBeFalse();
+        }
+
+        public class SomeObject
+        {
+            public int One { get; set; }
+            public string Two { get; set; }
+        }
 
         public class ObjectAssignableToSomeObject : SomeObject
         {
-            
+
         }
 
-		public class SampleController : Controller
-		{
-			public ActionResult Index(SomeObject viewModel, int id)
-			{
-				return View(viewModel);
-			}
+        public class SampleController : Controller