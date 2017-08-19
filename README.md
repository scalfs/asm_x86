# setas_x86 #

---------------------------------------------------------------------------
-------------------------Funções de desenho de setas-----------------------
---------------------------------------------------------------------------
   Exemplos ilustrativos para desenho de setas. 
   Os parametros que devem ser passados são posição "x" inicial (x0 em ax),
posição "y" inicial (y0 em bx), tamanho da seta (k em cx), seu tipo (di) e
sua cor (byte[cor]). Estes podem ser passados dentro das funções indicadas 
abaixo, ou podem ser passados no ponto do código onde são chamadas as 
funções de desenho.
   Para o projeto do elevador, recomenda-se criar uma função dessas (como 
"seta_subida_1andar_int"), indicando a posição onde cada seta ficará e 
atribuir seu tipo e cor quando essas funções forem chamadas. Assim pode-se 
apagar a seta anterior e redesenhá-la com o tipo e cor desejada.
   Caso a seta tenha sempre o mesmo tipo e cor, pode-se especificar dentro
da função, tirando a necessidade de sempre ter que atribuir fora, quando a
função for chamada. O mesmo pode ser feito com o tamanho da seta.
   Para apagar a seta, basta chamar a função utilizando os mesmos parametros,
porém com a cor "preto" em byte[cor].
---------------------------------------------------------------------------
