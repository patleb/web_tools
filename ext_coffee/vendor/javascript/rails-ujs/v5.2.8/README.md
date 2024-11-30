## `data-*` Attributes
* [`data-confirm`](#data-confirm) - Confirmation dialogs for links and forms
* [`data-disable-with`](#data-disable-with) - Automatic disabling of links and submit buttons in forms
* [`data-method`](#data-method) - Links that result in POST, PUT, or DELETE requests
* [`data-remote`](#data-remote) -  Make links and forms submit asynchronously with Ajax
* [`data-type`](#data-type) - Set Ajax request type, for `data-remote` requests
* [`data-params`](#data-params) - Add additional parameters to the request, for `data-remote` requests
* [`data-url`](#data-url) - Send AJAX request to the given url after change event on element, for `data-remote` requests


***


### `data-confirm`
**Confirmation dialogs for links and forms**

```html
<form data-confirm="Are you sure you want to submit?">...</form>
```

The presence of this attribute indicates that activating a link or submitting a form should be intercepted so the user can be presented a JavaScript `confirm()` dialog containing the text that is the value of the attribute. If the user chooses to cancel, the action doesn't take place.

The attribute is also allowed on form submit buttons. This allows you to customize the warning message depending on the button which was activated. In this case, you should *not* also have "data-confirm" on the form itself.

The default confirmation uses a javascript confirm dialog, but you can customize it by listening to the `confirm` event, that is fired just before the confirmation window appears to the user. To cancel this default confirmation, make the confirm handler to return `false`.

***

### `data-disable-with`
**Automatic disabling of links and submit buttons in forms**

```html
<input type="submit" value="Save" data-disable-with="Saving...">
```
This attribute indicates that a submit button, input field should get disabled while the form is submitting. This is to prevent accidental double-clicks from the user, which could result in duplicate HTTP requests that the backend may not detect as such. The value of the attribute is text that will become the new value of the button in its disabled state.

This also works for links with `data-method` attribute.

### `data-method`
**Links that result in POST, PUT, or DELETE requests**

```html
<a href="..." data-method="delete" rel="nofollow">Delete this entry</a>
```

Activating hyperlinks (usually by clicking or tapping on them) always results in an HTTP GET request. However, if your application is [RESTful][], some links are in fact actions that change data on the server and must be performed with non-GET requests. This attribute allows marking up such links with an explicit method such as "post", "put" or "delete".

The way it works is that, when the link is activated, it constructs a hidden form in the document with the "action" attribute corresponding to "href" value of the link and the method corresponding to "data-method" value, and submits that form.

Note for non-Rails backends: because submitting forms with HTTP methods other than GET and POST isn't widely supported across browsers, all other HTTP methods are actually sent over POST with the intended method indicated in the "_method" parameter. Rails framework automatically detects and compensates for this.

### `data-remote`
**Make links and forms submit asynchronously with Ajax**

```html
    <form data-remote="true" action="...">
      ...
    </form>
```

This attribute indicates that the link or form is to be submitted asynchronously; that is, without the page refreshing.

If the backend is configured to return snippets of JavaScript for these requests, those snippets will get executed on the page once requests are completed. Alternatively, you can handle the [[published custom events|ajax]] to hook into the lifecycle of the Ajax request.


### `data-type`
**Set Ajax request type, for `data-remote` requests**

```html
    <form data-remote="true" data-type="json">...</form>
```

This optional attribute defines the Ajax `dataType` explicitly when performing requests for "data-remote" elements.

[RESTful]: http://en.wikipedia.org/wiki/Representational_State_Transfer "Representational State Transfer"

### `data-params`
**Add additional parameters to the request, for `data-remote` requests**

```html
<a data-remote="true" data-method="post" data-params="param1=Hello+server" href="/test">AJAX action with POST request</a>
```

Activating the link will send AJAX POST request with additional parameter `param1` with value `Hello server`.

You can also use escaped JSON in `data-params`. It is useful when you create links with Rails's `link_to` helper and specifying parameters in a `Hash`.

```html
<a data-remote="true" data-method="post" data-params="{&quot;param1&quot;:&quot;Hello server&quot;}" href="/test">AJAX action with POST request</a>
```

### `data-url`
**Send AJAX request to the given url after change event on element, for `data-remote` requests**

```html
<input type="checkbox" name="task" id="task" value="1" data-url="/tasks/1" data-remote="true" data-method="post">
```

Changing the value of the checkbox (by clicking on it) will create new AJAX POST request to the URL defined in `data-url` with parameters obtained from jQuery `serialize()` method run on the checkbox.

This can be applied also to any other `input`, `select` or `textarea` elements.

# Custom events fired during "data-remote" requests

Forms and links marked with "data-remote" attribute are submitted with `jQuery.ajax()`. In addition to normal jQuery [Ajax "global" events][global], these custom events are fired from those DOM elements:

<table>
  <thead>
    <tr>
      <th>event name</th>
      <th>parameters after <i>event</i>*</th>
      <th>when</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>ajax:before</code></td>
      <td></td>
      <td>before the whole ajax business , aborts if stopped</td>
    </tr>
    <tr>
      <td><code>ajax:beforeSend</code></td>
      <td>[xhr, settings]</td>
      <td>before the request is sent, aborts if stopped</td>
    </tr>
    <tr>
      <td><code>ajax:send</code></td>
      <td>[xhr]</td>
      <td>when the request is sent</td>
    </tr>
    <tr>
      <td><code>ajax:success</code></td>
      <td>[data, status, xhr]</td>
      <td>after completion, if the HTTP response was a success</td>
    </tr>
    <tr>
      <td><code>ajax:error</code></td>
      <td>[xhr, status, error]</td>
      <td>after completion, if the server returned an error</td>
    </tr>
    <tr>
      <td><code>ajax:complete</code></td>
      <td>[xhr, status]</td>
      <td>after the request has been completed, no matter what outcome</td>
    </tr>
    <tr>
      <td><code>ajax:aborted:required</code></td>
      <td>[elements]</td>
      <td>when there are blank required fields in a form, submits anyway if stopped</td>
    </tr>
    <tr>
      <td><code>ajax:aborted:file</code></td>
      <td>[elements]</td>
      <td>if there are non-blank input:file fields in a form, aborts if stopped</td>
    </tr>
  </tbody>
</table>

### Important
_* All handlers bound to jQuery events are always passed the event object as the first argument. Extra parameters denotes the parameters passed *after* the event argument. E.g. if the Extra parameters are listed as `[xhr, settings]`, then to access them, you would define your handler with `function(event, xhr, settings){}`. See [this article](http://blog.bigbinary.com/2012/05/11/jquery-ujs-and-jquery-trigger.html) for a more in-depth explanation._

_** Opera is inconsistent in its handling of jQuery ajax error responses, so relying on the values of `xhr.status`, `status`, or `error` in an `ajax:error` callback handler may cause inconsistent behavior in Opera._

## Stoppable events

If you stop `ajax:before` or `ajax:beforeSend` by returning `false` from the handler method, the Ajax request will never take place. The `ajax:before` event is also useful for manipulating form data before serialization. The `ajax:beforeSend` event is also useful for adding custom request headers.

If you stop the `ajax:aborted:required` event, the default behavior of aborting the form submission will be canceled, and thus the form will be submitted anyway.

If you stop the `ajax:aborted:file` event, the default behavior of allowing the browser to submit the form via normal means (i.e. non-AJAX submission) will be canceled and the form will not be submitted at all. This is useful for implementing your own AJAX file upload workaround.

## Example usage

When processing a request failed on the server, it might return the error message as HTML:

```js
$('#account_settings').on('ajax:error', function(event, xhr, status, error) {
  // insert the failure message inside the "#account_settings" element
  $(this).append(xhr.responseText)
});
```

Set custom HTTP headers just for a specific type of forms:

```js
$('form.new_conversation').on('ajax:beforeSend', function(event, xhr, settings) {
  xhr.setRequestHeader('X-Awesome', 'enabled');
});
```

[global]: http://docs.jquery.com/Ajax_Events