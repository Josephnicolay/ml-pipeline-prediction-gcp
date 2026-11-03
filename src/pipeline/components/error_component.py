from kfp.v2.dsl import component

@component
def error(msg: str):
    raise RuntimeError(msg)