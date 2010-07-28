using System.Collections.Generic;
using System.Web;
using System.Web.Mvc;
using MvcContrib.ActionResults;
using MvcContrib.Filters;
using NUnit.Framework;
using Rhino.Mocks;

namespace MvcContrib.UnitTests.Filters
{
    [TestFixture]
    public class PassParametersDuringRedirectAttributeTester
    {
        private PassParametersDuringRedirectAttribute _filter;
        private SomeObject _someObject;
        private ActionExecutingContext _fakeActionExecutingContext;

        [SetUp]
        public void Setup()
        {
            _filter = new PassParametersDuringRedirectAttribute();
            _someObject = new SomeObject { One = 1, Two = "two" };

            _fakeActionExecutingContext = new ActionExecutingContext()
                {
                    Controller = new SampleController(),
                    ActionParameters = new Dictionary<string, object>(),
                    ActionDescriptor = GetActionDescriptorStubForIndexAction()
                };

            var stubContext = MockRepository.GenerateStub<HttpContextBase>();
            var stubRequest = MockRepository.GenerateStub<HttpRequestBase>();
            stubRequest.RequestType = "GET";

            stubContext.Stub(s => s.Request).Return(stubRequest);
            _fakeActionExecutingContext.HttpContext = stubContext;
        }

        [Test]
        public void OnActionExecuting_should_only_load_parameters_from_temp_data_if_the_current_HTTP_request_is_GET()
        {
            //Assigning TempData parameters on POSTs was trashing models that were set by a custom model binder.
            _fakeActionExecutingContext.HttpContext.Request.RequestType = "POST";

            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;

            _filter.OnActionExecuting(_fakeActionExecutingContext);

            _fakeActionExecutingContext.ActionParameters.Count.ShouldEqual(0);
        }

        [Test]
        public void OnActionExecuting_should_load_the_parameter_values_out_of_TempData_when_they_match_both_name_and_type_of_a_parameter_of_the_action_being_executed()
        {
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;

            _filter.OnActionExecuting(_fakeActionExecutingContext);

            _fakeActionExecutingContext.ActionParameters["viewModel"].ShouldEqual(_someObject);
            _fakeActionExecutingContext.ActionParameters["id"].ShouldEqual(5);
        }

        [Test]
        public void OnActionExecuting_should_load_the_parameter_values_out_of_TempData_when_they_match_the_name_and_are_assignable_to_the_type_of_a_parameter_of_the_action_being_executed()
        {
            var objectAssignableToSomeObject = new ObjectAssignableToSomeObject();

            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = objectAssignableToSomeObject;

            _filter.OnActionExecuting(_fakeActionExecutingContext);

            _fakeActionExecutingContext.ActionParameters["viewModel"].ShouldEqual(objectAssignableToSomeObject);

        }

        [Test]
        public void OnActionExecuting_should_not_load_the_parameter_values_out_of_TempData_which_do_not_have_matching_name_and_assignable_type_of_a_parameter_of_the_action_being_executed()
        {
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "theNameOfThisParameterDoesNotMatch"] = _someObject;
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = "the type of this parameter does not match";

            _filter.OnActionExecuting(_fakeActionExecutingContext);

            _fakeActionExecutingContext.ActionParameters.ContainsKey("theNameOfThisParameterDoesNotMatch").ShouldBeFalse();
            _fakeActionExecutingContext.ActionParameters.ContainsKey("param2").ShouldBeFalse();
        }

        [Test]
        public void OnActionExecuting_should_not_load_null_parameter_values()
        {
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = null;

            _filter.OnActionExecuting(_fakeActionExecutingContext);

            _fakeActionExecutingContext.ActionParameters.ContainsKey("viewModel").ShouldBeFalse();
        }


        [Test]
        public void Matching_stored_parameters_values_should_be_kept_in_TempData()
        {
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;

            _filter.OnActionExecuting(_fakeActionExecutingContext);
            _fakeActionExecutingContext.Controller.TempData.Save(_fakeActionExecutingContext, MockRepository.GenerateStub<ITempDataProvider>());

            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel").ShouldBeTrue();
            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id").ShouldBeTrue();

        }

        [Test]
        public void Non_matching_stored_parameter_values_should_be_not_be_kept_in_TempData()
        {
            var actionDescriptorWithNoParameters = MockRepository.GenerateStub<ActionDescriptor>();
            actionDescriptorWithNoParameters.Stub(ad => ad.GetParameters()).Return(new ParameterDescriptor[] { });

            _fakeActionExecutingContext.ActionDescriptor = actionDescriptorWithNoParameters;

            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"] = _someObject;
            _fakeActionExecutingContext.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"] = 5;

            _filter.OnActionExecuting(_fakeActionExecutingContext);
            _fakeActionExecutingContext.Controller.TempData.Save(_fakeActionExecutingContext, MockRepository.GenerateStub<ITempDataProvider>());

            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel").ShouldBeFalse();
            _fakeActionExecutingContext.Controller.TempData.ContainsKey(PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id").ShouldBeFalse();

        }

        [Test]
        public void OnActionExecuted_should_store_parameters_in_tempdata_when_result_is_generic_RedirectToRouteResult()
        {
            var context = new ActionExecutedContext()
            {
                Result = new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5)),
                Controller = new SampleController()
            };

            _fakeActionExecutingContext.Result =
                new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5));

            _filter.OnActionExecuted(context);
            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"].ShouldEqual(_someObject);
            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "id"].ShouldEqual(5);
        }

        [Test]
        public void Should_not_remove_null_parameters_from_the_route_values()
        {
            var context = new ActionExecutedContext
            {
                Result = new RedirectToRouteResult<SampleController>(x => x.Index(null, 5)),
                Controller = new SampleController()
            };

            _filter.OnActionExecuted(context);

            context.Controller.TempData[PassParametersDuringRedirectAttribute.RedirectParameterPrefix + "viewModel"].ShouldBeNull();
        }

        [Test]
        public void Should_remove_items_from_routevalues_once_stored_in_tempdata()
        {
            var result = new RedirectToRouteResult<SampleController>(x => x.Index(_someObject, 5));
            var context = new ActionExecutedContext()
            {
                Result = result,
                Controller = new SampleController()
            };

            _filter.OnActionExecuted(context);
            result.RouteValues.ContainsKey("viewModel").ShouldBeFalse();
        }

        public class SomeObject
        {
            public int One { get; set; }
            public string Two { get; set; }
        }

        public class ObjectAssignableToSomeObject : SomeObject
        {

        }

        public class SampleController : Controller
        {
            public ActionResult Index(SomeObject viewModel, int id)
            {
                return View(viewModel);
            }

            public ActionResult Save(SomeObject updateModel, int someId)
            {
                return this.RedirectToAction(c => c.Index(updateModel, someId));
            }
        }


        private static ActionDescriptor GetActionDescriptorStubForIndexAction()
        {
            var firstParameterDescriptor = MockRepository.GenerateStub<ParameterDescriptor>();
            firstParameterDescriptor.Stub(pd => pd.ParameterName).Return("viewModel");
            firstParameterDescriptor.Stub(pd => pd.ParameterType).Return(typeof(SomeObject));

            var secondParameterDescriptor = MockRepository.GenerateStub<ParameterDescriptor>();
            secondParameterDescriptor.Stub(pd => pd.ParameterName).Return("id");
            secondParameterDescriptor.Stub(pd => pd.ParameterType).Return(typeof(int));

            var actionDescriptor = MockRepository.GenerateStub<ActionDescriptor>();
            actionDescriptor.Stub(descriptor => descriptor.GetParameters()).Return(new[] { firstParameterDescriptor, secondParameterDescriptor });
            return actionDescriptor;
        }
    }
}