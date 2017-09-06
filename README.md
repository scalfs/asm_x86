# Desenho de setas na interface de vídeo para processador 8086

## Requisitos

Download e instale [DosBox](https://www.dosbox.com/)

Abra o DosBox e monte a pasta do seu projeto

`mount -c \home\user\setas_x86`

`c:`

Montagem: `nasm setas`

Executável: `freelink setas`

Para executar: `setas.exe`

## Funções ilustrativas para desenho de seta
   Os parametros que devem ser passados são posição "x" inicial (x0 em ax),
posição "y" inicial (y0 em bx), tamanho da seta (k em cx), seu tipo (di) e
sua cor (byte[cor]). Estes podem ser passados dentro das funções indicadas 
abaixo, ou podem ser passados no ponto do código onde são chamadas as 
funções de desenho.
   
   Para o projetos que pretendem usar este código, recomenda-se criar uma função indicando a posição onde cada seta ficará e 
atribuir seu tipo e cor quando essas funções forem chamadas. Assim pode-se 
apagar a seta anterior e redesenhá-la com o tipo e cor desejada.
   
   Caso a seta tenha sempre o mesmo tipo e cor, pode-se especificar dentro
da função, tirando a necessidade de sempre ter que atribuir fora, quando a
função for chamada. O mesmo pode ser feito com o tamanho da seta.
   
   Para apagar a seta, basta chamar a função utilizando os mesmos parametros,
porém com a cor "preto" em byte[cor].