import { delay } from 'lodash'
import { measurePlausibleEvent } from './plausible_analytics.js'

class SPICopyButton {
  installCopyEvent(button, contentElement, analyticsEvent) {
    // Nothing to do unless *both* of these are valid.
    if (!button || !contentElement) return

    button.addEventListener('click', (event) => {
      // Stop any form that this button may be contained within from submitting.
      event.preventDefault()

      // The contentElement can be different types of element so grab the content depending on element type.
      var contentToCopy = ''
      if (contentElement.matches('input')) {
        contentToCopy = contentElement.value
      } else {
        contentToCopy = contentElement.textContent
      }

      // Copy the content and let the user know.
      navigator.clipboard.writeText(contentToCopy).then(() => {
        // Keep a copy of the button's text label, then change it.
        const oldButtonText = button.textContent
        button.textContent = 'Copied!'

        // Then change it back after a short delay.
        delay(() => {
          button.textContent = oldButtonText
        }, 1000)

        // Log the analytics event.
        measurePlausibleEvent(analyticsEvent)
      })
    })
  }
}

export class SPICopyPackageURLButton extends SPICopyButton {
  constructor() {
    super()

    document.addEventListener('turbo:load', () => {
      // Create the "Copy Package URL" button immediately after the URL element.
      const packageURLElement = document.getElementById('package_url')
      if (!packageURLElement) return

      // Remove any old buttons from the Turbo restored page.
      const parentElement = packageURLElement.parentElement
      const oldButtonElement = parentElement.querySelector('button')
      if (oldButtonElement) oldButtonElement.remove()

      // Given that the button will only work with JavaScript available, we should use JavaScript to create it!
      const buttonElement = document.createElement('button')
      buttonElement.textContent = 'Copy'
      parentElement.appendChild(buttonElement)
      this.installCopyEvent(buttonElement, packageURLElement, 'Copy Package URL Button')
    })
  }
}

export class SPICopyableInput extends SPICopyButton {
  constructor() {
    super()

    document.addEventListener('turbo:load', () => {
      // Create a copy button inside every relevant form element.
      const elements = document.querySelectorAll('form.copyable_input')
      elements.forEach((formElement) => {
        // Get the first/only input element inside the form.
        const inputElement = formElement.querySelector('input')
        if (!inputElement) return

        // Whenever the input is clicked, select all text. Don't attach to the `focus` event
        // here, as `mouseup` happens after and placing the event on `focus` means it's too
        // easy to accidentally select all the text.
        inputElement.addEventListener('mouseup', (event) => {
          event.target.select()
        })

        // Remove the old button, if it exists, from the Turbo restored page.
        const oldButtonElement = formElement.querySelector('button')
        if (oldButtonElement) oldButtonElement.remove()

        // Given that the button will only work with JavaScript available, we should use JavaScript to create it!
        const buttonElement = document.createElement('button')
        buttonElement.textContent = inputElement.dataset.buttonName
        formElement.appendChild(buttonElement)

        // Add the copy event to the newly created button.
        this.installCopyEvent(buttonElement, inputElement, inputElement.dataset.eventName)
      })
    })
  }
}
