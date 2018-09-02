[n, k] = System.argv()

{n, _} = Integer.parse(n)
{k, _} = Integer.parse(k)

Boss.start(n, k)

:timer.sleep(1000)
Boss.printAns