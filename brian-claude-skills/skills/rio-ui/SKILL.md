---
name: rio-ui
description: Use when building Python web applications with Rio (rio.dev). Covers component creation, state management, layouts, event handling, and two-way binding. Triggers on Rio app development, rio.Component creation, or pure-Python web UI tasks. Rio requires no HTML/CSS/JS. Extends python-development skill.
---

# Rio UI Framework

Extends the `python-development` skill. Rio is a pure-Python UI framework for web apps—no HTML, CSS, or JavaScript required.

## Principles

**Component Model**
- **Declarative UI** - Define what the UI looks like, Rio handles updates
- **State drives UI** - Change attributes, Rio rebuilds automatically
- **Components are dataclasses** - Define state as class attributes with type hints
- **build() returns UI** - The `build` method defines component structure

**Layout**
- **Natural sizing first** - Components request their needed space
- **Containers distribute space** - Row, Column, Grid handle distribution
- **grow_x/grow_y for expansion** - Request extra available space
- **align_x/align_y for positioning** - Position within allocated space

**State Management**
- **Assign to trigger rebuild** - `self.count = 5` triggers UI update
- **Use self.bind() for two-way binding** - Sync input values with state
- **Avoid mutating lists/dicts in place** - Reassign to trigger updates

## Installation

Add to `pyproject.toml`:

```toml
[project]
dependencies = [
    "rio-ui",
]
```

Or for a standalone script:

```python
# /// script
# dependencies = ["rio-ui"]
# requires-python = ">=3.12"
# ///
```

## CLI Commands

```bash
uv run rio new                          # Create new project (interactive)
uv run rio new my-app --type website    # Create website project
uv run rio new my-app --template "Tic-Tac-Toe"  # Use template
uv run rio run                          # Run development server
```

## Basic Component

```python
import rio

class Counter(rio.Component):
    count: int = 0

    def _increment(self) -> None:
        self.count += 1

    def build(self) -> rio.Component:
        return rio.Column(
            rio.Text(f"Count: {self.count}"),
            rio.Button("Increment", on_press=self._increment),
        )
```

## Running the App

```python
# Run in browser
app = rio.App(build=Counter)
app.run_in_browser()

# Or run as desktop window
app.run_in_window()
```

## Layout Components

### Row and Column

```python
def build(self) -> rio.Component:
    return rio.Column(
        rio.Text("Header", style="heading1"),
        rio.Row(
            rio.Button("Left"),
            rio.Button("Center"),
            rio.Button("Right"),
            spacing=1,
        ),
        rio.Text("Footer"),
        spacing=2,
        align_x=0.5,  # Center horizontally
    )
```

### Grid

```python
def build(self) -> rio.Component:
    return rio.Grid(
        [rio.Text("Row 1, Col 1"), rio.Text("Row 1, Col 2")],
        [rio.Text("Row 2, Col 1"), rio.Text("Row 2, Col 2")],
        row_spacing=1,
        column_spacing=1,
    )
```

### Card

```python
def build(self) -> rio.Component:
    return rio.Card(
        rio.Column(
            rio.Text("Card Title", style="heading2"),
            rio.Text("Card content goes here."),
            spacing=1,
        ),
        margin=2,
    )
```

## Common Components

### Text and Headings

```python
rio.Text("Regular text")
rio.Text("Heading", style="heading1")  # heading1, heading2, heading3, text
rio.Text("Styled", style=rio.TextStyle(
    fill=rio.Color.from_hex("#ff0000"),
    font_weight="bold",
))
```

### Buttons

```python
rio.Button("Click me", on_press=self._handle_click)
rio.Button("Icon", icon="material/add")
rio.Button("Disabled", is_sensitive=False)
```

### Text Input

```python
class Form(rio.Component):
    name: str = ""

    def build(self) -> rio.Component:
        return rio.TextInput(
            label="Name",
            text=self.bind().name,  # Two-way binding
        )
```

### Dropdown

```python
class Selector(rio.Component):
    choice: str = "option1"

    def build(self) -> rio.Component:
        return rio.Dropdown(
            label="Select",
            options=["option1", "option2", "option3"],
            selected_value=self.bind().choice,
        )
```

### Switch and Checkbox

```python
class Toggles(rio.Component):
    enabled: bool = False
    checked: bool = False

    def build(self) -> rio.Component:
        return rio.Column(
            rio.Switch(is_on=self.bind().enabled),
            rio.Checkbox(is_on=self.bind().checked),
        )
```

### Number Input

```python
class NumberForm(rio.Component):
    quantity: int = 1

    def build(self) -> rio.Component:
        return rio.NumberInput(
            label="Quantity",
            value=self.bind().quantity,
            minimum=1,
            maximum=100,
            decimals=0,
        )
```

### Image

```python
rio.Image(rio.URL("https://example.com/image.png"), width=10, height=10)
rio.Image(path_to_local_file)
```

## Two-Way Binding

Use `self.bind()` to create two-way bindings between component state and input values:

```python
class LoginForm(rio.Component):
    username: str = ""
    password: str = ""
    remember_me: bool = False

    def _submit(self) -> None:
        print(f"Login: {self.username}")

    def build(self) -> rio.Component:
        return rio.Card(
            rio.Column(
                rio.TextInput(label="Username", text=self.bind().username),
                rio.TextInput(label="Password", text=self.bind().password, is_secret=True),
                rio.Checkbox(is_on=self.bind().remember_me),
                rio.Button("Login", on_press=self._submit),
                spacing=1,
            ),
        )
```

## Event Handling

```python
class Interactive(rio.Component):
    message: str = ""

    def _on_button_press(self) -> None:
        self.message = "Button pressed!"

    async def _on_async_action(self) -> None:
        # Async handlers are supported
        await some_async_operation()
        self.message = "Done!"

    def build(self) -> rio.Component:
        return rio.Column(
            rio.Button("Press me", on_press=self._on_button_press),
            rio.Button("Async", on_press=self._on_async_action),
            rio.Text(self.message),
        )
```

## Component Sizing

```python
rio.Button(
    "Sized Button",
    min_width=10,      # Minimum width in Rio units
    min_height=3,      # Minimum height
    grow_x=True,       # Expand to fill horizontal space
    grow_y=False,      # Don't expand vertically
    align_x=0.5,       # Center when extra space (0=left, 1=right)
    align_y=0,         # Top align (0=top, 1=bottom)
)
```

## Margins and Spacing

```python
rio.Text(
    "Padded text",
    margin=2,           # All sides
    margin_x=1,         # Left and right
    margin_y=2,         # Top and bottom
    margin_left=1,      # Individual sides
    margin_top=2,
)

rio.Row(
    rio.Button("A"),
    rio.Button("B"),
    spacing=2,          # Space between children
)
```

## Conditional Rendering

```python
class ConditionalUI(rio.Component):
    show_details: bool = False

    def build(self) -> rio.Component:
        children = [rio.Text("Always visible")]

        if self.show_details:
            children.append(rio.Text("Details shown"))

        return rio.Column(*children)
```

## Lists and Dynamic Content

```python
class TodoList(rio.Component):
    items: list[str] = []

    def _add_item(self) -> None:
        # Reassign to trigger rebuild (don't use .append())
        self.items = [*self.items, f"Item {len(self.items) + 1}"]

    def build(self) -> rio.Component:
        return rio.Column(
            rio.Button("Add Item", on_press=self._add_item),
            *[rio.Text(item) for item in self.items],
            spacing=1,
        )
```

## App Structure

```python
import rio

class MainPage(rio.Component):
    def build(self) -> rio.Component:
        return rio.Column(
            rio.Text("My App", style="heading1"),
            rio.Text("Welcome to the app"),
            align_x=0.5,
            align_y=0.5,
            grow_x=True,
            grow_y=True,
        )

app = rio.App(
    name="My App",
    build=MainPage,
)

if __name__ == "__main__":
    app.run_in_browser()
```

## Common Patterns

### Loading State

```python
class DataFetcher(rio.Component):
    is_loading: bool = False
    data: str = ""

    async def _fetch(self) -> None:
        self.is_loading = True
        self.data = await fetch_data()
        self.is_loading = False

    def build(self) -> rio.Component:
        if self.is_loading:
            return rio.Text("Loading...")

        return rio.Column(
            rio.Text(self.data),
            rio.Button("Refresh", on_press=self._fetch),
        )
```

### Component Composition

```python
class UserCard(rio.Component):
    name: str
    email: str

    def build(self) -> rio.Component:
        return rio.Card(
            rio.Column(
                rio.Text(self.name, style="heading3"),
                rio.Text(self.email),
                spacing=0.5,
            ),
        )

class UserList(rio.Component):
    users: list[dict] = []

    def build(self) -> rio.Component:
        return rio.Column(
            *[UserCard(name=u["name"], email=u["email"]) for u in self.users],
            spacing=1,
        )
```

## Important Notes

- **State changes via assignment** - Always assign new values; mutating in place won't trigger rebuilds
- **Type hints required** - Rio uses type hints to detect state attributes
- **No __init__ needed** - Rio components are dataclasses; define attributes at class level
- **Async supported** - Event handlers can be async functions
- **Units are relative** - Width/height/spacing values are in Rio's unit system, not pixels