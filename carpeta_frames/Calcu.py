import tkinter as tk
import math

# Función para procesar la entrada
def calcular():
    try:
        expresion = entrada.get()
        resultado = eval(expresion, {"__builtins__": None}, math.__dict__)
        entrada.delete(0, tk.END)
        entrada.insert(tk.END, str(resultado))
    except Exception:
        entrada.delete(0, tk.END)
        entrada.insert(tk.END, "Error")

# Función para agregar texto en la entrada
def agregar_texto(texto):
    entrada.insert(tk.END, texto)

# Función para borrar último carácter
def borrar_ultimo():
    actual = entrada.get()
    entrada.delete(0, tk.END)
    entrada.insert(tk.END, actual[:-1])

# Función para limpiar
def limpiar():
    entrada.delete(0, tk.END)

# Configuración ventana
root = tk.Tk()
root.title("Calculadora Científica")
root.resizable(False, False)

# Entrada
entrada = tk.Entry(root, width=25, font=("Arial", 18), borderwidth=5, relief="ridge")
entrada.grid(row=0, column=0, columnspan=6, padx=5, pady=5)

# Botones
botones = [
    ("7", 1, 0), ("8", 1, 1), ("9", 1, 2), ("/", 1, 3), ("sqrt(", 1, 4), ("pi", 1, 5),
    ("4", 2, 0), ("5", 2, 1), ("6", 2, 2), ("*", 2, 3), ("**", 2, 4), ("e", 2, 5),
    ("1", 3, 0), ("2", 3, 1), ("3", 3, 2), ("-", 3, 3), ("(", 3, 4), (")", 3, 5),
    ("0", 4, 0), (".", 4, 1), ("+", 4, 2), ("log(", 4, 3), ("sin(", 4, 4), ("cos(", 4, 5),
    ("tan(", 5, 0), ("abs(", 5, 1), ("round(", 5, 2), ("exp(", 5, 3), ("asin(", 5, 4), ("acos(", 5, 5)
]

for (texto, fila, col) in botones:
    tk.Button(root, text=texto, width=6, height=2, font=("Arial", 12),
              command=lambda t=texto: agregar_texto(t)).grid(row=fila, column=col, padx=2, pady=2)

# Botones especiales
tk.Button(root, text="C", width=6, height=2, font=("Arial", 12), command=limpiar).grid(row=6, column=0, padx=2, pady=2)
tk.Button(root, text="⌫", width=6, height=2, font=("Arial", 12), command=borrar_ultimo).grid(row=6, column=1, padx=2, pady=2)
tk.Button(root, text="=", width=15, height=2, font=("Arial", 12), command=calcular).grid(row=6, column=2, columnspan=2, padx=2, pady=2)
tk.Button(root, text="Salir", width=6, height=2, font=("Arial", 12), command=root.quit).grid(row=6, column=4, padx=2, pady=2)

# Soporte para presionar Enter y calcular
root.bind("<Return>", lambda event: calcular())
root.bind("<BackSpace>", lambda event: borrar_ultimo())

root.mainloop()
